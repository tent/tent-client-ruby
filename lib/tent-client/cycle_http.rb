class TentClient

  # Proxies to Faraday and cycles through server urls
  #   until either non left or response status in the 200s or 400s
  class CycleHTTP
    attr_reader :client, :server_urls
    def initialize(client, &faraday_block)
      @faraday_block = faraday_block
      @client = client
      @server_urls = client.server_urls.dup
    end

    def new_http
      @http = Faraday.new(:url => server_urls.shift) do |f|
        @faraday_block.call(f)
      end
    end

    def http
      @http || new_http
    end

    %w{ head get put post patch delete }.each do |verb|
      define_method verb do |*args, &block|
        res = http.send(verb, *args, &block)
        return res unless server_urls.any?
        case res.status
        when 200...300, 400...500
          res
        else
          new_http
          send(verb, *args, &block)
        end
      end
    end

    def options(url = nil, params = nil, headers = nil)
      http.run_request(:options, url, nil, headers) do |request|
        request.params.update(params) if params
        yield request if block_given?
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      http.respond_to?(method_name, include_private)
    end

    def method_missing(method_name, *args, &block)
      if http.respond_to?(method_name)
        http.send(method_name, *args, &block)
      else
        super
      end
    end
  end
end
