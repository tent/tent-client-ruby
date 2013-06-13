require 'faraday_middleware'
require 'hawk'

class TentClient
  module Middleware
    class Authentication < Faraday::Middleware
      AUTHORIZATION_HEADER = 'Authorization'.freeze
      CONTENT_TYPE_HEADER = 'Content-Type'.freeze

      def initialize(app, credentials)
        super(app)
        @credentials = {
          :id => credentials[:id],
          :key => credentials[:hawk_key],
          :algorithm => credentials[:hawk_algorithm]
        } if credentials
      end

      def call(env)
        env[:request_headers][AUTHORIZATION_HEADER] = build_authorization_header(env) if @credentials
        @app.call env
      end

      private

      def build_authorization_header(env)
        Hawk::Client.build_authorization_header(
          :credentials => @credentials,
          :ts => Time.now.to_i,
          :payload => request_body(env),
          :content_type => request_content_type(env),
          :method => request_method(env),
          :port => request_port(env),
          :host => request_host(env),
          :request_uri => request_path(env)
        )
      end

      def request_body(env)
        if env[:body].respond_to?(:read)
          body = env[:body].read
          env[:body].rewind if env[:body].respond_to?(:rewind)
          body
        else
          env[:body]
        end
      end

      def request_content_type(env)
        env[:request_headers]['Content-Type'].to_s.split(';').first
      end

      def request_method(env)
        env[:method].to_s.upcase
      end

      def request_port(env)
        env[:url].port || (env[:url].scheme == 'https' ? 443 : 80)
      end

      def request_host(env)
        env[:url].host
      end

      def request_path(env)
        env[:url].to_s.sub(%r{\A#{env[:url].scheme}://#{env[:url].host}(:#{env[:url].port})?}, '') # maintain query and fragment
      end
    end
  end
end
