require "net/http"

# Bot checks for the public sign-up form, run before any record is saved or
# email sent. Usage:
#
#   result = SignupGuard.new(params: params, remote_ip: ip).call
#   result.success?  # => false when the sign-up should be rejected
#   result.error     # => SignupGuard::Rejection (reason for logs, message for users)
class SignupGuard
  Rejection = Struct.new(:reason, :message, keyword_init: true)

  HONEYPOT_FIELD = :website
  TOKEN_FIELD    = :form_token
  TURNSTILE_FIELD = "cf-turnstile-response".freeze

  TOKEN_PURPOSE  = :signup_form
  TOKEN_TTL      = 2.hours
  MIN_FILL_TIME  = 3.seconds

  BLOCKED_EMAIL_DOMAINS = %w[
    1win.xyz 1win.com
    gmzil.com gamil.com gmai.com gmail.con gmail.ru
  ].freeze

  LINK_PATTERN = %r{
    https?://   |
    www\.       |
    t\.me/      |
    @           |
    \.(?:com|xyz|ru|net|io|app|link|top|online|site|bet)\b
  }xi

  TURNSTILE_VERIFY_URL = URI("https://challenges.cloudflare.com/turnstile/v0/siteverify").freeze

  GENERIC_MESSAGE = "We couldn't verify your sign-up. Please wait a moment and try again.".freeze

  class << self
    def verifier
      Rails.application.message_verifier(TOKEN_PURPOSE)
    end

    # Signed render timestamp embedded in the form.
    def issue_form_token(now: Time.current)
      verifier.generate(now.to_f, expires_at: now + TOKEN_TTL, purpose: TOKEN_PURPOSE)
    end

    def turnstile_site_key   = ENV["TURNSTILE_SITE_KEY"].presence
    def turnstile_secret_key = ENV["TURNSTILE_SECRET_KEY"].presence

    def turnstile_enabled?
      turnstile_site_key.present? && turnstile_secret_key.present?
    end
  end

  # turnstile_http: callable(uri, form_hash) -> Net::HTTPResponse-like (#body);
  # injectable for tests.
  def initialize(params:, remote_ip:, now: Time.current, turnstile_http: nil)
    @params         = params
    @remote_ip      = remote_ip
    @now            = now
    @turnstile_http = turnstile_http || method(:post_to_turnstile)
  end

  def call
    check_honeypot ||
      check_timing ||
      check_email_domain ||
      check_names ||
      check_turnstile ||
      Result.success
  end

  private

  attr_reader :params, :remote_ip, :now

  def reject(reason, message = GENERIC_MESSAGE)
    Result.failure(Rejection.new(reason: reason, message: message))
  end

  def check_honeypot
    reject(:honeypot) if params[HONEYPOT_FIELD].present?
  end

  def check_timing
    token = params[TOKEN_FIELD].to_s
    return reject(:missing_token) if token.blank?

    rendered_at = self.class.verifier.verified(token, purpose: TOKEN_PURPOSE)
    return reject(:invalid_or_expired_token) unless rendered_at.is_a?(Numeric)

    elapsed = now.to_f - rendered_at
    reject(:too_fast) if elapsed < MIN_FILL_TIME.to_f
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ArgumentError
    reject(:invalid_or_expired_token)
  end

  def check_email_domain
    domain = email.split("@", 2).last.to_s
    return if domain.blank?

    blocked = BLOCKED_EMAIL_DOMAINS.any? { |d| domain == d || domain.end_with?(".#{d}") }
    reject(:blocked_email_domain, "Please use a different email address.") if blocked
  end

  def check_names
    full_name    = params.dig(:user, :full_name).to_s
    company_name = params.dig(:company, :name).to_s

    if LINK_PATTERN.match?(full_name) || LINK_PATTERN.match?(company_name)
      reject(:link_in_name, "Your name and company name can't contain links or email addresses.")
    end
  end

  def check_turnstile
    return unless self.class.turnstile_enabled?

    token = params[TURNSTILE_FIELD].to_s
    return reject(:turnstile_missing, "Please complete the security check and try again.") if token.blank?

    response = @turnstile_http.call(
      TURNSTILE_VERIFY_URL,
      { "secret" => self.class.turnstile_secret_key, "response" => token, "remoteip" => remote_ip.to_s }
    )
    body = JSON.parse(response.body.to_s)

    return if body["success"] == true

    Rails.logger.info("[SignupGuard] turnstile rejected errors=#{Array(body['error-codes']).join(',')}")
    reject(:turnstile_failed, "Please complete the security check and try again.")
  rescue StandardError => e
    # Network errors, timeouts, bad JSON — fail closed.
    Rails.logger.error("[SignupGuard] turnstile verification error #{e.class}: #{e.message}")
    reject(:turnstile_error, "We couldn't complete the security check. Please try again.")
  end

  def email
    @email ||= params.dig(:user, :email).to_s.strip.downcase
  end

  def post_to_turnstile(uri, form)
    Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 5) do |http|
      request = Net::HTTP::Post.new(uri)
      request.set_form_data(form)
      http.request(request)
    end
  end
end
