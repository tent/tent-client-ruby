require 'openssl'
require 'base64'
require 'securerandom'

class TentClient
  module Middleware
    class MacAuth
      def initialize(app, options={})
        @app, @mac_key_id, @mac_key, @mac_algorithm = app, options[:mac_key_id], options[:mac_key], options[:mac_algorithm]
      end

      def call(env)
        sign_request(env) if auth_enabled?
        @app.call(env)
      end

      private

      def auth_enabled?
        @mac_key_id && @mac_key && @mac_algorithm
      end

      def sign_request(env)
        time = Time.now.to_i
        nonce = SecureRandom.hex(3)
        request_string = build_request_string(time, nonce, env)
        signature = Base64.encode64(OpenSSL::HMAC.digest(openssl_digest.new, @mac_key, request_string)).sub("\n", '')
        env[:request_headers]['Authorization'] = build_auth_header(time, nonce, signature)
      end

      def build_request_string(time, nonce, env)
        if env[:body].respond_to?(:read)
           body = env[:body].read
           env[:body].rewind
        else
          body = env[:body]
        end
        [time.to_s, nonce, env[:method].to_s.upcase, env[:url].request_uri, env[:url].host, env[:url].port, body, nil].join("\n")
      end

      def build_auth_header(time, nonce, signature)
        %Q(MAC id="#{@mac_key_id}", ts="#{time}", nonce="#{nonce}", mac="#{signature}")
      end

      def openssl_digest
        @openssl_digest ||= OpenSSL::Digest.const_get(@mac_algorithm.to_s.gsub(/hmac|-/, '').upcase)
      end
    end
  end
end
