require 'tent-client/version'
require 'faraday'
require 'faraday_middleware'

class TentClient
  autoload :Discovery, 'tent-client/discovery'
  autoload :LinkHeader, 'tent-client/link_header'
  autoload :Follower, 'tent-client/follower'
  autoload :Following, 'tent-client/following'
  autoload :Profile, 'tent-client/profile'
  autoload :App, 'tent-client/app'
  autoload :AppAuthorization, 'tent-client/app_authorization'
  autoload :Post, 'tent-client/post'

  require 'tent-client/middleware/accept_header'
  require 'tent-client/middleware/mac_auth'
  require 'tent-client/middleware/encode_json'

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
      f.use Middleware::EncodeJson unless @options[:skip_serialization]
      f.response :json, :content_type => /\bjson\Z/ unless @options[:skip_serialization]
      f.use Middleware::AcceptHeader
      f.use Middleware::MacAuth, @options
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

  def following
    Following.new(self)
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
