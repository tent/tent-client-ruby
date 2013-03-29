class TentClient

  # Proxies to Faraday and cycles through server urls
  #   until either non left or response status in the 200s or 400s
  class CycleHTTP
    attr_reader :client, :servers
    def initialize(client, &faraday_block)
      @faraday_block = faraday_block
      @client = client
      @servers = client.server_meta['servers'].sort_by { |s| s['preference'] }
    end

    def current_server
      @current_server || servers.first
    end

    def new_http
      @current_server = servers.shift
      @http = Faraday.new do |f|
        @faraday_block.call(f)
      end
    end

    def http
      @http ||= new_http
    end

    def named_url(name, params = {})
      current_server['urls'][name.to_s].to_s.gsub(/{([^}]+)}/) {
        param = (params.delete($1) || params.delete($1.to_sym)).to_s
        URI.encode_www_form_component(param)
      }
    end

    %w( options get head delete ).map(&:to_sym).each do |verb|
      define_method verb do |url, params={}, headers={}, &block|
        run_request(verb, url, params, nil, headers)
      end
    end

    %w( post put patch ).map(&:to_sym).each do |verb|
      define_method verb do |url, params={}, body=nil, headers={}, &block|
        run_request(verb, url, params, body, headers, &block)
      end
    end

    def run_request(verb, url, params, body, headers, &block)
      args = [verb, url, params, body, headers]
      if Symbol === url
        url = named_url(url, params || {})
      end

      res = http.run_request(verb, url, body, headers) do |request|
        request.params.update(params) if params
        yield request if block_given?
      end

      return res if servers.empty?

      case res.status
      when 200...300, 400...500
        res
      else
        new_http
        run_request(*args, &block)
      end
    rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
      new_http
      run_request(*args, &block)
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
