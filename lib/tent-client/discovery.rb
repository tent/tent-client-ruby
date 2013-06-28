require 'yajl'
require 'faraday'
require 'faraday_middleware'
require 'faraday_middleware/multi_json'
require 'nokogiri'
require 'tent-client/link_header'
require 'uri'

class TentClient
  class Discovery
    META_POST_REL = "https://tent.io/rels/meta-post".freeze

    def self.discover(client, entity_uri, options = {})
      new(client, entity_uri).discover(options)
    end

    attr_reader :client, :entity_uri
    attr_accessor :last_response
    def initialize(client, entity_uri)
      @client, @entity_uri = client, entity_uri
    end

    def discover(options = {})
      discover_res, meta_post_urls = perform_head_discovery || perform_get_discovery

      if meta_post_urls.empty?
        return options[:return_response] ? last_response : nil
      end

      meta_post_urls.uniq.each do |url|
        url = URI.join(discover_res.env[:url].to_s, url).to_s
        res = http.get(url) do |request|
          request.headers['Accept'] = POST_CONTENT_TYPE % "https://tent.io/types/meta/v0#"
        end

        if options[:return_response]
          return res
        elsif res.success? && (Hash === res.body)
          return res.body['post']
        end
      end
      nil
    end

    private

    def http
      @http ||= Faraday.new do |f|
        f.adapter *Array(client.faraday_adapter)
        f.response :follow_redirects
        f.response :multi_json, :content_type => /\bjson\Z/
      end
    end

    def perform_head_discovery
      res = http.head(entity_uri)
      self.last_response = res
      links = Array(perform_header_discovery(res))
      [res, links] if links.any?
    end

    def perform_get_discovery
      res = http.get(entity_uri)
      self.last_response = res
      [res, Array(perform_link_discovery(res))]
    end

    def perform_header_discovery(res)
      if header = res['Link']
        links = LinkHeader.parse(header).links.select { |l| l[:rel] == META_POST_REL }.map { |l| l.uri }
        links unless links.empty?
      end
    rescue LinkHeader::MalformedLinkHeader
    end

    def perform_link_discovery(res)
      return unless res['Content-Type'].to_s.downcase =~ %r{\Atext/html}
      Nokogiri::HTML(res.body).css(%(link[rel="#{META_POST_REL}"])).map { |l| l['href'] }
    end
  end
end
