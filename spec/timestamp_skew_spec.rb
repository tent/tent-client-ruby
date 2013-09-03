require 'spec_helper'
require 'tent-client'
require 'hawk'

describe TentClient do
  # - make request
  # - return valid skew header
  # - validate that request is retried with skew
  # - validate that subsequent requests are with new skew
  #
  # - make request
  # - return invalid skew header
  # - validate that request is not retried
  # - validate that subsequent requests use the original skew (0)

  def translate_credentials(credentials)
    _credentials = {}
    _credentials[:id] = credentials[:id]
    _credentials[:key] = credentials[:hawk_key]
    _credentials[:algorithm] = credentials[:hawk_algorithm]
    _credentials
  end

  let(:credentials) {
    {
      :id => '123456',
      :hawk_key => '2983d45yun89q',
      :hawk_algorithm => 'sha256'
    }
  }

  let(:skew) { 160 }

  let(:timestamp) { Time.now.to_i + skew } # future time

  let(:client) {
    TentClient.new(nil, :credentials => credentials)
  }

  let(:http_stubs) { [] }

  context "valid skew header" do
    let(:tsm_header) {
      Hawk::Server.build_tsm_header(
        :ts => timestamp,
        :credentials => translate_credentials(credentials)
      )
    }

    it "retries request with calculated timestamp skew" do
      http_stubs << stub_request(:get, "http://example.com").with { |request|
        request.headers['Authorization'] =~ %r{ts="#{timestamp - skew}"}
      }.to_return(
        :status => 401,
        :headers => {
          'WWW-Authenticate' => tsm_header
        }
      )

      http_stubs << stub_request(:get, "http://example.com").with { |request|
        request.headers['Authorization'] =~ %r{ts="#{timestamp}"}
      }.to_return(
        :status => 200
      )

      res = client.http.send(:get, "http://example.com")

      http_stubs.each do |stub|
        expect(stub).to have_been_requested
      end

      expect(res.status).to eql(200)
    end

    context "when retry is disabled" do
      let(:client) {
        TentClient.new(nil, :credentials => credentials, :ts_skew_retry_enabled => false)
      }

      it "calculates skew" do
        http_stubs << stub_request(:get, "http://example.com").with { |request|
          request.headers['Authorization'] =~ %r{ts="#{timestamp - skew}"}
        }.to_return(
          :status => 401,
          :headers => {
            'WWW-Authenticate' => tsm_header
          }
        )

        res = client.http.send(:get, "http://example.com")

        http_stubs.each do |stub|
          expect(stub).to have_been_requested
        end

        expect(res.status).to eql(401)
        expect(client.ts_skew).to eql(skew)
      end
    end
  end

  context "invalid skew header" do
    let(:invalid_tsm_header) {
      %(Hawk ts="#{timestamp}" tsm="invalidTsMac")
    }

    it "ignores header" do
      http_stubs << stub_request(:get, "http://example.com").with { |request|
        request.headers['Authorization'] =~ %r{ts="#{timestamp - skew}"}
      }.to_return(
        :status => 401,
        :headers => {
          'WWW-Authenticate' => invalid_tsm_header
        }
      )

      res = client.http.send(:get, "http://example.com")

      http_stubs.each do |stub|
        expect(stub).to have_been_requested
      end

      expect(res.status).to eql(401)
    end
  end
end
