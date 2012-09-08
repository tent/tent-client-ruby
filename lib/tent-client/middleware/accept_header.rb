class TentClient
  module Middleware
    class AcceptHeader
      def initialize(app)
        @app = app
      end

      def call(env)
        env[:request_headers]['Accept'] ||= MEDIA_TYPE
        @app.call(env)
      end
    end
  end
end
