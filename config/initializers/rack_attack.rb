# Rate limiting for sign-up and auth endpoints.
# See https://github.com/rack/rack-attack
#
# Client IPs are resolved with ClientIp (lib/client_ip.rb), which is safe
# behind Render's proxy (and Cloudflare, if present).

class Rack::Attack
  redis_url = Rails.application.credentials.redis_url || ENV["REDIS_URL"]

  Rack::Attack.cache.store =
    if Rails.env.test?
      ActiveSupport::Cache::MemoryStore.new
    elsif redis_url.present?
      ActiveSupport::Cache::RedisCacheStore.new(
        url:        redis_url,
        namespace:  "rack_attack",
        ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE },
        # Fail open: if Redis is down, requests are allowed through (and logged)
        # rather than taking the sign-up / login pages down with it.
        error_handler: ->(method:, returning:, exception:) {
          Rails.logger.error("[rack-attack] Redis error in #{method}: #{exception.class}: #{exception.message}")
        }
      )
    else
      Rails.logger.warn("[rack-attack] No REDIS_URL configured; falling back to per-process MemoryStore")
      ActiveSupport::Cache::MemoryStore.new
    end

  REGISTER_PATH = "/register".freeze

  def self.client_ip(req) = ClientIp.call(req)

  def self.register?(req) = req.post? && req.path == REGISTER_PATH

  # ── Sign-up ───────────────────────────────────────────────────────────────
  throttle("register/ip/10min", limit: 3, period: 10.minutes) do |req|
    client_ip(req) if register?(req)
  end

  throttle("register/ip/day", limit: 10, period: 1.day) do |req|
    client_ip(req) if register?(req)
  end

  # Global brake across all IPs (bots rotate addresses).
  throttle("register/global/hour", limit: 30, period: 1.hour) do |req|
    "global" if register?(req)
  end

  # ── Password reset & login ───────────────────────────────────────────────
  throttle("password_reset/ip", limit: 5, period: 1.hour) do |req|
    client_ip(req) if req.post? && req.path == "/users/password"
  end

  throttle("sign_in/ip", limit: 20, period: 5.minutes) do |req|
    client_ip(req) if req.post? && req.path == "/users/sign_in"
  end

  # ── Response ─────────────────────────────────────────────────────────────
  self.throttled_responder = lambda do |req|
    match   = req.env["rack.attack.match_data"] || {}
    period  = match[:period].to_i
    headers = { "content-type" => "text/plain" }
    headers["retry-after"] = (period - (match[:epoch_time].to_i % period)).to_s if period.positive?

    [429, headers, ["Too many requests. Please wait a while and try again.\n"]]
  end
end

ActiveSupport::Notifications.subscribe("throttle.rack_attack") do |_name, _start, _finish, _id, payload|
  req = payload[:request]
  Rails.logger.warn(
    "[rack-attack] throttled rule=#{req.env['rack.attack.matched']} " \
    "ip=#{Rack::Attack.client_ip(req)} remote_addr=#{req.get_header('REMOTE_ADDR')} " \
    "xff=#{req.get_header('HTTP_X_FORWARDED_FOR').inspect} " \
    "cf_ip=#{req.get_header('HTTP_CF_CONNECTING_IP').inspect} " \
    "method=#{req.request_method} path=#{req.path}"
  )
end
