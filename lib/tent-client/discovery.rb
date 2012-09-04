require 'nokogiri'

class TentClient
  class Discovery
    attr_accessor :url, :profile_urls, :primary_profile_url, :profile

    def initialize(client, url)
      @client, @url = client, url
    end

    def http
      @http ||= Faraday.new do |f|
        f.response :follow_redirects
        f.adapter *Array(@client.faraday_adapter)
      end
    end

    def perform
      @profile_urls = perform_head_discovery || perform_get_discovery || []
      @profile_urls.map! { |l| l =~ %r{\A/} ? URI.join(url, l).to_s : l }
    end

    def get_profile
      profile_urls.each do |url|
        res = @client.http.get(url)
        if res['Content-Type'] == MEDIA_TYPE
          @profile = res.body
          @primary_profile_url = url
          break
        end
      end
      [@profile, @primary_profile_url.to_s.sub(%r{/profile$}, '')]
    end

    def perform_head_discovery
      perform_header_discovery http.head(url)
    end

    def perform_get_discovery
      res = http.get(url)
      perform_header_discovery(res) || perform_html_discovery(res)
    end

    def perform_header_discovery(res)
      if header = res['Link']
        links = LinkHeader.parse(header).links.select { |l| l[:rel] == PROFILE_REL }.map { |l| l.uri }
        links unless links.empty?
      end
    end

    def perform_html_discovery(res)
      return unless res['Content-Type'] == 'text/html'
      Nokogiri::HTML(res.body).css(%(link[rel="#{PROFILE_REL}"])).map { |l| l['href'] }
    end
  end
end
