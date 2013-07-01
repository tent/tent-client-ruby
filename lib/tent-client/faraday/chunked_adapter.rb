require 'net/http'
require 'faraday/adapter/net_http'

module Faraday
  class Adapter

    class NetHttpStream < Adapter::NetHttp
      class BodyStream
        def initialize(env, &stream_body)
          @env, @stream_body = env, stream_body
          @read_body = false
        end

        def each(&block)
          return if @read_body
          @stream_body.call(block)
          @read_body = true
        end

        def read
          return @body if @body
          @body = ""
          each do |chunk|
            @body << chunk
          end
          @body
        end
      end

      def call(env)
        env[:request_body] = env[:body]

        request = new_request(env)

        stream_body = proc do |callback|
          @read_proc = callback
          request.resume
        end

        response = request.resume
        body = BodyStream.new(env, &stream_body)

        save_response(env, response.code.to_i, body) do |response_headers|
          response.each_header do |key, value|
            response_headers[key] = value
          end
        end

        @app.call(env)
      rescue *Adapter::NetHttp::NET_HTTP_EXCEPTIONS
        raise Error::ConnectionFailed, $!
      rescue Timeout::Error => err
        raise Faraday::Error::TimeoutError, err
      end

      private

      def new_request(env)
        uri = env[:url]
        Fiber.new do
          Net::HTTP.start(uri.host, uri.port) do |http|
            configure_ssl(http, env[:ssl]) if env[:url].scheme == 'https' and env[:ssl]

            request = create_request(env)

            req = env[:request]
            http.read_timeout = http.open_timeout = req[:timeout] if req[:timeout]
            http.open_timeout = req[:open_timeout]                if req[:open_timeout]

            http.request(request) do |response|
              Fiber.yield(response)

              response.read_body do |chunk|
                @read_proc.call(chunk)
              end
            end
          end
        end
      end

      def create_request(env)
        request = Net::HTTPGenericRequest.new \
          env[:method].to_s.upcase,    # request method
          !!env[:body],                # is there request body
          :head != env[:method],       # is there response body
          env[:url].request_uri,       # request uri path
          env[:request_headers]        # request headers

        if env[:request_body].respond_to?(:read)
          request.body_stream = env[:request_body]
        else
          request.body = env[:request_body]
        end
        request
      end
    end

    Adapter.register_middleware(:net_http_stream => NetHttpStream)
  end
end
