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
      current_server['urls'][name.to_s].to_s.gsub(/\{([^\}]+)\}/) {
        param = (params.delete($1) || params.delete($1.to_sym)).to_s
        URI.encode_www_form_component(param)
      }
    end

    %w( options get head delete ).map(&:to_sym).each do |verb|
      class_eval(<<-RUBY
        def #{verb}(url, params = {}, headers = {}, &block)
          run_request(#{verb.inspect}, url, params, nil, headers, &block)
        end
RUBY
      )
    end

    %w( post put patch ).map(&:to_sym).each do |verb|
      class_eval(<<-RUBY
        def #{verb}(url, params = {}, body = nil, headers = {}, &block)
          run_request(#{verb.inspect}, url, params, body, headers, &block)
        end
RUBY
      )
    end

    def multipart_request(verb, url, params, parts, headers = {}, &block)
      body = multipart_body(parts)
      run_request(verb.to_sym, url, params, body, headers) do |request|
        request.headers['Content-Type'] = "#{MULTIPART_CONTENT_TYPE}; boundary=#{MULTIPART_BOUNDARY}"
        request.headers['Content-Length'] = body.length.to_s
        yield(request) if block_given?
      end
    end

    def run_request(verb, url, params, body, headers, &block)
      args = [verb, url, params, body, headers]
      if Symbol === url
        name = url
        url = named_url(url, params || {})
      else
        name = nil
      end

      res = http.run_request(verb, url, body, headers) do |request|
        request.params.update(params) if params
        yield request if block_given?
      end

      if name
        res.env[:tent_server] = current_server
      end

      return res if servers.empty? || !name

      case res.status
      when 200...300, 400...500
        res
      else
        new_http
        run_request(*args, &block)
      end
    rescue Faraday::Error::TimeoutError, Faraday::Error::ConnectionFailed
      raise if servers.empty?
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

    private

    def multipart_body(parts)
      # group by category
      parts = parts.inject(Hash.new) do |memo, part|
        category = part[:category] || part['category']
        memo[category] ||= []
        memo[category] << part
        memo
      end

      # expend into request parts
      parts = parts.inject(Array.new) do |memo, (category, category_parts)|
        if category_parts.size > 1
          memo.concat category_parts.each_with_index.map { |part, index|
            headers = part[:headers] || part['headers']
            Faraday::Parts::FilePart.new(MULTIPART_BOUNDARY, "#{category}[#{index}]", upload_io(part), headers)
          }
        else
          part = category_parts.first
          headers = part[:headers] || part['headers']
          memo << Faraday::Parts::FilePart.new(MULTIPART_BOUNDARY, category, upload_io(part), :headers => headers)
        end
      end

      parts << Faraday::Parts::EpiloguePart.new(MULTIPART_BOUNDARY)
      Faraday::CompositeReadIO.new(parts)
    end

    def upload_io(part)
      Faraday::UploadIO.new(
        (part[:file] || part['file']) || StringIO.new(part[:data] || part['data']),
        part[:content_type] || part['content-type'],
        part[:filename] || part['filename']
      )
    end
  end
end
