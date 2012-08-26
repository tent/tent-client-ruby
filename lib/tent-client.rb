require 'tent-client/version'
require 'faraday'

class TentClient
  autoload :Discovery, 'tent-client/discovery'
  autoload :LinkHeader, 'tent-client/link_header'

  def self.http
    @http ||= Faraday.new do |f|
      f.adapter Faraday.default_adapter
    end
  end
end
