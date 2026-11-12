require "test_helper"

class RegistrationsSignupGuardTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    Rack::Attack.reset!
    @rendered_at = Time.current
    @token = SignupGuard.issue_form_token(now: @rendered_at)
  end

  def signup_params(overrides = {})
    {
      form_token: @token,
      website:    "",
      company: {
        name: "Acme Technologies Ltd", slug: "acme-technologies", payroll_email: "payroll@acme.co.uk",
        country: "United Kingdom", currency: "GBP", currency_symbol: "£", payroll_day: 25, timezone: "London"
      },
      user: {
        full_name: "Hannah Moore", email: "hannah@acme.co.uk",
        password: "password123", password_confirmation: "password123"
      }
    }.deep_merge(overrides)
  end

  def submit(params, after: 10.seconds)
    travel_to(@rendered_at + after) { post registration_path, params: params }
  end

  def assert_rejected(params, **opts)
    assert_no_difference(["User.count", "Company.count"]) do
      assert_no_enqueued_jobs { submit(params, **opts) }
    end
    assert_response :unprocessable_entity
  end

  test "new renders the form token and hidden honeypot, without turnstile when unconfigured" do
    get new_registration_path
    assert_response :success
    assert_select "input[type=hidden][name=form_token]"
    assert_select "div[aria-hidden=true] input[name=website][tabindex='-1'][autocomplete=off]"
    assert_select ".cf-turnstile", count: 0
  end

  test "valid sign-up still works with Turnstile disabled" do
    assert_difference(["User.count", "Company.count"], 1) do
      submit(signup_params)
    end
    assert_redirected_to admin_dashboard_path("acme-technologies")
    assert_enqueued_with(job: OnboardingNudgeJob)
    assert_enqueued_with(job: OnboardingCheckinJob)
  end

  test "honeypot rejects" do
    assert_rejected signup_params(website: "spam.example")
  end

  test "too-fast submit rejects" do
    assert_rejected signup_params, after: 1.second
  end

  test "bad or missing token rejects" do
    assert_rejected signup_params(form_token: "forged")
    assert_rejected signup_params.except(:form_token)
  end

  test "blocked email domain rejects with a friendly message" do
    assert_rejected signup_params(user: { email: "bot@1win.xyz" })
    assert_match "use a different email address", response.body
  end

  test "link in name rejects" do
    assert_rejected signup_params(user: { full_name: "Claim bonus at 1win.com" })
  end
end
