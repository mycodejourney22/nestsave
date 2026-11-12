require "test_helper"

class SignupGuardTest < ActiveSupport::TestCase
  FakeResponse = Struct.new(:body)

  setup do
    @rendered_at = Time.current
    @token = SignupGuard.issue_form_token(now: @rendered_at)
  end

  def params(overrides = {})
    base = {
      form_token: @token,
      website:    "",
      company:    { name: "Acme Technologies Ltd" },
      user:       { full_name: "Hannah Moore", email: "hannah@acme.co.uk" }
    }
    ActionController::Parameters.new(base.deep_merge(overrides))
  end

  def guard(p = params, now: @rendered_at + 10.seconds, **opts)
    SignupGuard.new(params: p, remote_ip: "203.0.113.5", now: now, **opts).call
  end

  def with_turnstile_env
    old = ENV.to_h.slice("TURNSTILE_SITE_KEY", "TURNSTILE_SECRET_KEY")
    ENV["TURNSTILE_SITE_KEY"]   = "site"
    ENV["TURNSTILE_SECRET_KEY"] = "secret"
    yield
  ensure
    ENV.delete("TURNSTILE_SITE_KEY")
    ENV.delete("TURNSTILE_SECRET_KEY")
    old.each { |k, v| ENV[k] = v }
  end

  test "accepts a normal sign-up" do
    assert guard.success?
  end

  test "rejects a filled honeypot" do
    assert_equal :honeypot, guard(params(website: "http://spam.example")).error.reason
  end

  test "rejects a missing token" do
    assert_equal :missing_token, guard(params(form_token: "")).error.reason
  end

  test "rejects a tampered or garbage token" do
    assert_equal :invalid_or_expired_token, guard(params(form_token: "#{@token}x")).error.reason
    assert_equal :invalid_or_expired_token, guard(params(form_token: "garbage")).error.reason
  end

  test "rejects a token signed by a different verifier" do
    other = Rails.application.message_verifier(:other).generate(@rendered_at.to_f)
    assert_equal :invalid_or_expired_token, guard(params(form_token: other)).error.reason
  end

  test "rejects an expired token" do
    travel_to(@rendered_at + 2.hours + 1.minute) do
      assert_equal :invalid_or_expired_token, guard(now: Time.current).error.reason
    end
  end

  test "rejects a submit faster than 3 seconds" do
    assert_equal :too_fast, guard(now: @rendered_at + 1.second).error.reason
    assert guard(now: @rendered_at + 3.seconds).success?
  end

  test "rejects blocked email domains, case-insensitively" do
    %w[x@1win.xyz x@1WIN.com x@gmzil.com x@gamil.com x@gmai.com x@gmail.con x@gmail.ru x@mail.1win.xyz].each do |email|
      assert_equal :blocked_email_domain, guard(params(user: { email: email })).error.reason, email
    end
    assert guard(params(user: { email: "real@gmail.com" })).success?
  end

  test "rejects links or emails in full name or company name" do
    [
      { user: { full_name: "Win big http://spam" } },
      { user: { full_name: "visit www.spam" } },
      { user: { full_name: "join t.me/spam" } },
      { user: { full_name: "me@example" } },
      { company: { name: "Bonus 1win.xyz" } },
      { company: { name: "Casino.BET promo" } },
      { company: { name: "spam.online" } }
    ].each do |override|
      assert_equal :link_in_name, guard(params(override)).error.reason, override.inspect
    end
  end

  test "does not flag ordinary names that merely contain TLD-like letters" do
    assert guard(params(company: { name: "Planet Company Ltd." }, user: { full_name: "J. R. Netherton" })).success?
  end

  test "turnstile is skipped when keys are not configured" do
    called = false
    result = guard(turnstile_http: ->(*) { called = true })
    assert result.success?
    refute called
  end

  test "turnstile success passes and sends secret, response and remoteip" do
    with_turnstile_env do
      sent = nil
      http = ->(uri, form) { sent = [uri, form]; FakeResponse.new({ success: true }.to_json) }
      result = guard(params("cf-turnstile-response" => "tok"), turnstile_http: http)

      assert result.success?
      assert_equal "challenges.cloudflare.com", sent[0].host
      assert_equal({ "secret" => "secret", "response" => "tok", "remoteip" => "203.0.113.5" }, sent[1])
    end
  end

  test "turnstile rejects missing, failed, and errored verifications" do
    with_turnstile_env do
      assert_equal :turnstile_missing, guard.error.reason

      failed = ->(*) { FakeResponse.new({ success: false, "error-codes" => ["invalid-input-response"] }.to_json) }
      assert_equal :turnstile_failed, guard(params("cf-turnstile-response" => "tok"), turnstile_http: failed).error.reason

      boom = ->(*) { raise Net::OpenTimeout, "timed out" }
      assert_equal :turnstile_error, guard(params("cf-turnstile-response" => "tok"), turnstile_http: boom).error.reason
    end
  end
end
