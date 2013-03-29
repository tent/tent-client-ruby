require 'tent-client/version'
require 'tent-client/discovery'
require 'tent-client/cycle_http'

class TentClient

  attr_reader :entity_uri
  attr_writer :faraday_adapter
  def initialize(entity_uri, options = {})
    @server_meta = options.delete(:server_meta)
    @entity_uri, @options = entity_uri, options
  end

  def server_meta
    @server_meta ||= Discovery.discover(entity_uri)
  end

  def new_http
    CycleHTTP.new(self) do |f|
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

end
