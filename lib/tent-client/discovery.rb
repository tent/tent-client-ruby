class TentClient
  class Discovery
    attr_accessor :url, :profiles

    def initialize(url)
      @url = url
    end

    def perform
      @profiles = perform_header_discovery || perform_html_discovery
    end

    def perform_header_discovery
      res = TentClient.http.head(url)
      if header = res['Link']
        links = LinkHeader.parse(header).links
        tent_profiles = links.select { |l| l[:rel] == 'profile' && l[:type] == 'application/vnd.tent.profile+json' }.
                              map { |l| l.uri }
        tent_profiles unless tent_profiles.empty?
      end
    end

    def perform_html_discovery

    end
  end
end
