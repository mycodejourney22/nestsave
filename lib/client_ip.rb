require "ipaddr"

# Resolves the real client IP for a request arriving through Render's proxy.
#
# Rack's `request.ip` already walks X-Forwarded-For from the right, skipping
# private/loopback hops, and returns the first public address — i.e. the
# address that actually connected to Render's edge. That is spoof-resistant:
# a client can prepend fake entries to X-Forwarded-For, but cannot change the
# entry Render's proxy appends.
#
# If Cloudflare sits in front of Render, that "connecting" address is a
# Cloudflare edge IP shared by many users. Only in that case do we trust
# CF-Connecting-IP (which Cloudflare overwrites, so clients can't forge it
# when the request genuinely came through Cloudflare).
module ClientIp
  # https://www.cloudflare.com/ips/
  CLOUDFLARE_RANGES = %w[
    173.245.48.0/20 103.21.244.0/22 103.22.200.0/22 103.31.4.0/22
    141.101.64.0/18 108.162.192.0/18 190.93.240.0/20 188.114.96.0/20
    197.234.240.0/22 198.41.128.0/17 162.158.0.0/15 104.16.0.0/13
    104.24.0.0/14 172.64.0.0/13 131.0.72.0/22
    2400:cb00::/32 2606:4700::/32 2803:f800::/32 2405:b500::/32
    2405:8100::/32 2a06:98c0::/29 2c0f:f248::/32
  ].map { |cidr| IPAddr.new(cidr) }.freeze

  module_function

  # Accepts a Rack::Request / ActionDispatch::Request (anything with #ip and #get_header).
  def call(request)
    ip = request.ip
    cf = request.get_header("HTTP_CF_CONNECTING_IP").to_s.strip

    if cf.present? && cloudflare?(ip) && valid_ip?(cf)
      cf
    else
      ip
    end
  end

  def cloudflare?(ip)
    addr = IPAddr.new(ip.to_s)
    CLOUDFLARE_RANGES.any? { |range| range.include?(addr) }
  rescue IPAddr::Error
    false
  end

  def valid_ip?(ip)
    IPAddr.new(ip)
    true
  rescue IPAddr::Error
    false
  end
end
