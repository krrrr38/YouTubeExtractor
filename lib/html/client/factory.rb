require 'faraday'
require 'faraday_middleware'

module HTML
  module Client
  end
end

module HTML::Client::Factory
  def client(host, ua = "Youtube::Extractor::HTML::Client")
    Faraday.new host do |builder|
      builder.request :url_encoded
      builder.headers["User-Agent"] = ua
      builder.use FaradayMiddleware::FollowRedirects
      builder.adapter :net_http
    end
  end
end
