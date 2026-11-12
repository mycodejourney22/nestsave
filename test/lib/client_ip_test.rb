require "test_helper"

class ClientIpTest < ActiveSupport::TestCase
  def request_for(env)
    Rack::Request.new(Rack::MockRequest.env_for("/", env))
  end

  test "uses the rightmost public X-Forwarded-For hop behind a private proxy" do
    req = request_for("REMOTE_ADDR" => "10.1.2.3", "HTTP_X_FORWARDED_FOR" => "6.6.6.6, 203.0.113.9")
    assert_equal "203.0.113.9", ClientIp.call(req)
  end

  test "trusts CF-Connecting-IP only when the connecting hop is a Cloudflare edge" do
    via_cf = request_for("REMOTE_ADDR" => "10.1.2.3", "HTTP_X_FORWARDED_FOR" => "162.158.1.1",
                         "HTTP_CF_CONNECTING_IP" => "203.0.113.9")
    assert_equal "203.0.113.9", ClientIp.call(via_cf)

    spoofed = request_for("REMOTE_ADDR" => "10.1.2.3", "HTTP_X_FORWARDED_FOR" => "198.51.100.1",
                          "HTTP_CF_CONNECTING_IP" => "203.0.113.9")
    assert_equal "198.51.100.1", ClientIp.call(spoofed)
  end
end
