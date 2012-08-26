require 'nokogiri'

class TentClient
  class Discovery
    attr_accessor :url, :profiles

    def initialize(url)
      @url = url
    end

    def perform
      @profiles = perform_head_discovery || perform_get_discovery
    end

    def perform_head_discovery
      perform_header_discovery TentClient.http.head(url)
    end

    def perform_get_discovery
      res = TentClient.http.get(url)
      perform_header_discovery(res) || perform_html_discovery(res)
    end

    def perform_header_discovery(res)
      if header = res['Link']
        links = LinkHeader.parse(header).links
        tent_profiles = links.select { |l| l[:rel] == 'profile' && l[:type] == PROFILE_MEDIA_TYPE }.
                              map { |l| l.uri }
        tent_profiles unless tent_profiles.empty?
      end
    end

    def perform_html_discovery(res)
      return unless res['Content-Type'] == 'text/html'
      links = Nokogiri::HTML(res.body).css('link[rel=profile]')
      links.select { |l| l['type'] == PROFILE_MEDIA_TYPE }.map { |l| l['href'] }
    end
  end
end
