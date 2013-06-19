require 'tent-client/version'
require 'faraday'
require 'tent-client/faraday/utils'
require 'tent-client/multipart-post/parts'
require 'tent-client/tent_type'
require 'tent-client/middleware/content_type_header'
require 'tent-client/middleware/encode_json'
require 'tent-client/middleware/authentication'
require 'tent-client/cycle_http'
require 'tent-client/discovery'
require 'tent-client/post'

##
# Ruby 1.8.7 compatibility
require 'uri'
unless URI.respond_to?(:encode_www_form_component)
  require 'addressable/uri'

  URI.class_eval do
    def self.encode_www_form_component(str)
      Addressable::URI.encode_component(
        str.to_s.gsub(/(\r\n|\n|\r)/, "\r\n"),
        Addressable::URI::CharacterClasses::UNRESERVED
      ).gsub("%20", "+")
    end
  end
end

class TentClient
  POST_CONTENT_TYPE = %(application/vnd.tent.post.v0+json; type="%s").freeze
  POST_MENTIONS_CONTENT_TYPE = %(application/vnd.tent.post-mentions.v0+json).freeze
  POST_VERSIONS_CONTENT_TYPE = %(application/vnd.tent.post-versions.v0+json).freeze
  POST_CHILDREN_CONTENT_TYPE = %(application/vnd.tent.post-children.v0+json).freeze
  OAUTH_TOKEN_CONTENT_TYPE = %(application/vnd.tent.oauth.token.v0+json).freeze
  MULTIPART_CONTENT_TYPE = 'multipart/form-data'.freeze
  MULTIPART_BOUNDARY = "-----------TentPart".freeze

  attr_reader :entity_uri
  attr_writer :faraday_adapter, :server_meta_post
  def initialize(entity_uri, options = {})
    @server_meta_post = options.delete(:server_meta)
    @faraday_adapter = options.delete(:faraday_adapter)
    @entity_uri, @options = entity_uri, options
  end

  def server_meta
    server_meta_post['content'] if server_meta_post
  end

  def server_meta_post
    @server_meta_post ||= Discovery.discover(self, entity_uri)
  end

  def primary_server
    server_meta['servers'].sort_by { |s| s['preference'] }.first
  end

  def new_http
    CycleHTTP.new(self) do |f|
      f.use Middleware::ContentTypeHeader
      f.use Middleware::EncodeJson unless @options[:skip_serialization]
      f.use Middleware::Authentication, @options[:credentials] if @options[:credentials]
      f.response :multi_json, :content_type => /\bjson\Z/ unless @options[:skip_serialization] || @options[:skip_response_serialization]
      f.adapter *Array(faraday_adapter)
    end
  end

  def http
    @http ||= new_http
  end

  def faraday_adapter
    @faraday_adapter || Faraday.default_adapter
  end

  def hex_digest(data)
    if data.kind_of?(IO)
      _data = data.read
      data.rewind
      data = _data
    end
    Digest::SHA512.new.update(data).to_s[0...64]
  end

  def post
    Post.new(self)
  end

  def oauth_redirect_uri(params = {})
    uri = URI(primary_server['urls']['oauth_auth'])

    query = params.inject([]) { |m, (k,v)| m << "#{k}=#{URI.encode_www_form_component(v)}"; m }.join('&')
    uri.query ? uri.query += "&#{query}" : uri.query = query

    uri
  end

  def oauth_token_exchange(data, &block)
    new_block = proc do |request|
      request.headers['Content-Type'] = OAUTH_TOKEN_CONTENT_TYPE
      yield(request) if block_given?
    end
    http.post(:oauth_token, params = {}, {
      :token_type => 'https://tent.io/oauth/hawk-token'
    }.merge(data), &new_block)
  end

end
