require "test_helper"

class RackAttackTest < ActionDispatch::IntegrationTest
  setup    { Rack::Attack.reset! }
  teardown { Rack::Attack.reset! }

  # No form token: SignupGuard rejects with 422, but the throttle still counts it.
  def post_register(ip, xff: nil)
    env = { "REMOTE_ADDR" => ip }
    env["HTTP_X_FORWARDED_FOR"] = xff if xff
    post registration_path, params: { company: { name: "Acme" }, user: { email: "a@example.com" } }, env: env
  end

  test "POST /register is limited to 3 per 10 minutes per IP" do
    3.times do
      post_register("198.51.100.1")
      assert_response :unprocessable_entity
    end

    post_register("198.51.100.1")
    assert_response :too_many_requests
    assert_equal "text/plain", response.media_type
    assert response.headers["retry-after"].to_i.positive?

    post_register("198.51.100.2")
    assert_response :unprocessable_entity, "a different IP should be unaffected"
  end

  test "POST /register is limited to 10 per day per IP across 10-minute windows" do
    start = Time.current.beginning_of_day + 1.hour
    statuses = []
    4.times do |window|
      travel_to(start + (window * 11).minutes) do
        3.times { post_register("198.51.100.3"); statuses << response.status }
      end
    end
    assert_equal 10, statuses.count(422)
    assert_equal 2, statuses.count(429)
  end

  test "POST /register has a global cap of 30 per hour across all IPs" do
    travel_to(Time.current.beginning_of_hour + 1.minute) do
      30.times do |i|
        post_register("192.0.2.#{i + 1}")
        assert_response :unprocessable_entity
      end
      post_register("192.0.2.200")
      assert_response :too_many_requests
    end
  end

  test "GET /register is not throttled" do
    5.times { get new_registration_path, env: { "REMOTE_ADDR" => "198.51.100.9" } }
    assert_response :success
  end

  test "throttles on the proxy-appended client IP, ignoring spoofed X-Forwarded-For prefixes" do
    4.times { |i| post_register("10.0.0.1", xff: "1.2.3.#{i}, 198.51.100.7") }
    assert_response :too_many_requests
  end

  test "POST /users/password is limited to 5 per hour per IP" do
    env = { "REMOTE_ADDR" => "198.51.100.4" }
    5.times { post user_password_path, params: { user: { email: "x@example.com" } }, env: env }
    refute_equal 429, response.status
    post user_password_path, params: { user: { email: "x@example.com" } }, env: env
    assert_response :too_many_requests
  end

  test "POST /users/sign_in is limited to 20 per 5 minutes per IP" do
    env = { "REMOTE_ADDR" => "198.51.100.5" }
    creds = { user: { email: "x@example.com", password: "nope" } }
    20.times { post user_session_path, params: creds, env: env }
    refute_equal 429, response.status
    post user_session_path, params: creds, env: env
    assert_response :too_many_requests
  end
end
