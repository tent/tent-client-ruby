require 'faraday_middleware'

class TentClient
  module Middleware
    class ContentTypeHeader < Faraday::Middleware
      CONTENT_TYPE_HEADER = 'Content-Type'.freeze
      MEDIA_TYPE = %(application/vnd.tent.post.v0+json; type="%s").freeze

      def call(env)
        if env[:body] && Hash === env[:body] && !env[:request_headers][CONTENT_TYPE_HEADER]
          env[:request_headers][CONTENT_TYPE_HEADER] = MEDIA_TYPE % (env[:body]['type'] || env[:body][:type])

          if env[:request]['tent.notification']
            env[:request_headers][CONTENT_TYPE_HEADER] << %(; rel="https://tent.io/rels/notification")
          end
        end

        @app.call env
      end
    end
  end
end
