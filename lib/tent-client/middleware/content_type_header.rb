require 'faraday_middleware'

class TentClient
  module Middleware
    class ContentTypeHeader < Faraday::Middleware
      CONTENT_TYPE_HEADER = 'Content-Type'.freeze
      MEDIA_TYPE = %w(application/vnd.tent.post.v0+json; type="%s").freeze

      def call(env)
        if env[:body] && Hash === env[:body]
          env[:request_headers][CONTENT_TYPE_HEADER] ||= MEDIA_TYPE % (env[:body]['type'] || env[:body][:type])
        end

        @app.call env
      end
    end
  end
end
