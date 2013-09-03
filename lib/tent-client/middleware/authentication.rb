require 'faraday_middleware'
require 'hawk'

class TentClient
  module Middleware
    class Authentication < Faraday::Middleware
      AUTHORIZATION_HEADER = 'Authorization'.freeze
      CONTENT_TYPE_HEADER = 'Content-Type'.freeze

      MAX_RETRIES = 1.freeze

      def initialize(app, credentials, options = {})
        super(app)

        @credentials = {
          :id => credentials[:id],
          :key => credentials[:hawk_key],
          :algorithm => credentials[:hawk_algorithm]
        } if credentials

        @ts_skew = options[:ts_skew] || 0
        @update_ts_skew = options[:update_ts_skew] || lambda {}
        @ts_skew_retry_enabled = options[:ts_skew_retry_enabled]
        @retry_count = 0
      end

      def call(env)
        set_auth_header(env)
        res = @app.call(env)

        tsm_header = res.env[:response_headers]['WWW-Authenticate']

        if tsm_header && (tsm_header =~ /tsm/) && (skew = timestamp_skew_from_header(tsm_header)) && @retry_count < MAX_RETRIES
          @update_ts_skew.call(skew)
          @ts_skew = skew

          @retry_count += 1

          return call(env) if @ts_skew_retry_enabled
        end

        res
      end

      private

      def set_auth_header(env)
        env[:request_headers][AUTHORIZATION_HEADER] = build_authorization_header(env) if @credentials
      end

      def timestamp
        Time.now.to_i + @ts_skew
      end

      def timestamp_skew_from_header(header)
        Hawk::Client.calculate_time_offset(header, :credentials => @credentials)
      end

      def build_authorization_header(env)
        Hawk::Client.build_authorization_header(
          :credentials => @credentials,
          :ts => timestamp,
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
