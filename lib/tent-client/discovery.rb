require 'yajl'
require 'faraday'
require 'faraday_middleware'
require 'faraday_middleware/multi_json'
require 'nokogiri'
require 'tent-client/link_header'

class TentClient
  class Discovery
    META_POST_REL = "https://tent.io/rels/meta-post".freeze

    def self.discover(entity_uri)
      new(entity_uri).discover
    end

    attr_reader :entity_uri
    def initialize(entity_uri)
      @entity_uri = entity_uri
    end

    def discover
      meta_post_urls = Array(perform_head_discovery || perform_get_discovery)
      return if meta_post_urls.empty?
      meta_post_urls.uniq.each do |url|
        res = http.get(url)
        return res.body if res.success?
      end
      nil
    end

    private

    def http
      @http ||= Faraday.new do |f|
        f.adapter :net_http
        f.response :follow_redirects
        f.response :multi_json, :content_type => /\bjson\Z/
      end
    end

    def perform_head_discovery
      perform_header_discovery http.head(entity_uri)
    end

    def perform_get_discovery
      perform_link_discovery http.get(entity_uri)
    end

    def perform_header_discovery(res)
      if header = res['Link']
        links = LinkHeader.parse(header).links.select { |l| l[:rel] == META_POST_REL }.map { |l| l.uri }
        links unless links.empty?
      end
    end

    def perform_link_discovery(res)
      return unless res['Content-Type'].to_s.downcase =~ %r{\Atext/html}
      Nokogiri::HTML(res.body).css(%(link[rel="#{META_POST_REL}"])).map { |l| l['href'] }
    end
  end
end
