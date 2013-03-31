require 'faraday_middleware'

class TentClient
  module Middleware
    # FaradayMiddleware::EncodeJson with our media type
    # https://github.com/pengwynn/faraday_middleware/blob/master/lib/faraday_middleware/request/encode_json.rb
    class EncodeJson < Faraday::Middleware
      CONTENT_TYPE_HEADER = 'Content-Type'.freeze

      dependency do
        require 'yajl' unless defined?(Yajl)
      end

      def call(env)
        match_content_type(env) do |data|
          env[:body] = encode data
        end
        @app.call env
      end

      def encode(data)
        Yajl::Encoder.encode(data)
      end

      def match_content_type(env)
        if process_request?(env)
          yield env[:body] unless env[:body].respond_to?(:to_str)
        end
      end

      def process_request?(env)
        type = request_type(env)
        has_body?(env) and (type.empty? or type =~ /\bjson\Z/)
      end

      def has_body?(env)
        body = env[:body] and !(body.respond_to?(:to_str) and body.empty?)
      end

      def request_type(env)
        type = env[:request_headers][CONTENT_TYPE_HEADER].to_s
        type = type.split(';', 2).first if type.index(';')
        type
      end
    end
  end
end
