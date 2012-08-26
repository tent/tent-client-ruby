require 'tent-client/version'
require 'faraday'
require 'faraday_middleware'

class TentClient
  autoload :Discovery, 'tent-client/discovery'
  autoload :LinkHeader, 'tent-client/link_header'

  BASE_MEDIA_TYPE = 'application/vnd.tent.%s+json'.freeze
  PROFILE_MEDIA_TYPE = (BASE_MEDIA_TYPE % 'profile').freeze

  class << self
    attr_accessor :faraday_adapter

    def http
      @http ||= Faraday.new do |f|
        f.use FaradayMiddleware::FollowRedirects
        # hack to allow injecting test stubs
        if faraday_adapter.length > 1
          f.adapter faraday_adapter.first, &faraday_adapter.last
        else
          f.adapter *faraday_adapter
        end
      end
    end

    def faraday_adapter
      @faraday_adapter || [Faraday.default_adapter]
    end

    def discover(url)
      Discovery.new(url).perform
    end
  end
end
