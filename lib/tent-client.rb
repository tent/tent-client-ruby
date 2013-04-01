require 'tent-client/version'
require 'faraday'
require 'tent-client/tent_type'
require 'tent-client/middleware/content_type_header'
require 'tent-client/middleware/encode_json'
require 'tent-client/cycle_http'
require 'tent-client/discovery'
require 'tent-client/post'

class TentClient
  MEDIA_TYPES = {
    :post => 'application/vnd.tent.post.v0+json'
  }.freeze

  attr_reader :entity_uri
  attr_writer :faraday_adapter
  def initialize(entity_uri, options = {})
    @server_meta = options.delete(:server_meta)
    @faraday_adapter = options.delete(:faraday_adapter)
    @entity_uri, @options = entity_uri, options
  end

  def server_meta
    @server_meta ||= Discovery.discover(self, entity_uri)
  end

  def new_http
    CycleHTTP.new(self) do |f|
      f.use Middleware::ContentTypeHeader
      f.use Middleware::EncodeJson unless @options[:skip_serialization]
      f.response :multi_json, :content_type => /\bjson\Z/ unless @options[:skip_serialization]
      f.adapter *Array(faraday_adapter)
    end
  end

  def http
    @http ||= new_http
  end

  def faraday_adapter
    @faraday_adapter || Faraday.default_adapter
  end

  def post
    Post.new(self)
  end

end
