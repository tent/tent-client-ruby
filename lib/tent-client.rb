require 'tent-client/version'
require 'tent-client/discovery'

class TentClient

  attr_reader :entity_uri
  def initialize(entity_uri, options = {})
    @server_meta = options.delete(:server_meta)
    @entity_uri, @options = entity_uri, options
  end

  def server_meta
    @server_meta ||= Discovery.discover(entity_uri)
  end

end
