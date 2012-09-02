require 'tent-client/version'
require 'faraday'
require 'faraday_middleware'

class TentClient
  autoload :Discovery, 'tent-client/discovery'
  autoload :LinkHeader, 'tent-client/link_header'
  autoload :Follower, 'tent-client/follower'
  autoload :MacAuthMiddleware, 'tent-client/mac_auth_middleware'

  BASE_MEDIA_TYPE = 'application/vnd.tent.%s+json'.freeze
  PROFILE_MEDIA_TYPE = (BASE_MEDIA_TYPE % 'profile').freeze

  attr_reader :faraday_adapter, :server_url

  def initialize(server_url = nil, options={})
    @server_url = server_url
    @faraday_adapter = options.delete(:faraday_adapter)
    @options = options
  end

  def http
    @http ||= Faraday.new(:url => server_url) do |f|
      f.request :json unless @options[:skip_serialization]
      f.response :json, :content_type => /\bjson\Z/ unless @options[:skip_serialization]
      f.use MacAuthMiddleware, @options
      f.adapter *Array(faraday_adapter)
    end
  end

  def faraday_adapter
    @faraday_adapter || Faraday.default_adapter
  end

  def server_url=(v)
    @server_url = v
    @http = nil # reset Faraday connection
  end

  def discover(url)
    Discovery.new(self, url).tap { |d| d.perform }
  end

  def follower
    Follower.new(self)
  end
end
