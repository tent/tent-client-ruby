require 'tent-client/version'
require 'faraday'
require 'faraday_middleware'

class TentClient
  autoload :Discovery, 'tent-client/discovery'
  autoload :LinkHeader, 'tent-client/link_header'
  autoload :Follower, 'tent-client/follower'
  autoload :Profile, 'tent-client/profile'
  autoload :App, 'tent-client/app'
  autoload :AppAuthorization, 'tent-client/app_authorization'
  autoload :MacAuthMiddleware, 'tent-client/mac_auth_middleware'
  autoload :Post, 'tent-client/post'

  MEDIA_TYPE = 'application/vnd.tent.v0+json'.freeze
  PROFILE_REL = 'https://tent.io/rels/profile'.freeze

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

  def app
    App.new(self)
  end

  def post
    Post.new(self)
  end

  def profile
    Profile.new(self)
  end
end
