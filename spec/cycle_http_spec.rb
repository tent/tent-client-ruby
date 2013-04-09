require 'spec_helper'
require 'tent-client/cycle_http'

describe TentClient::CycleHTTP do

  let(:http_stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:server_urls) { %w(http://example.org/tent http://foo.example.com/tent http://baz.example.com/tent) }
  let(:entity_uri) { server_urls.first }
  let(:server_meta) {
    {
      "entity" => entity_uri,
      "previous_entities" => [],
      "servers" => server_urls.each_with_index.map { |server_url, index|
        {
          "version" => "0.3",
          "urls" => {
            "oauth_auth" => "#{server_url}/oauth/authorize",
            "oauth_token" => "#{server_url}/oauth/token",
            "posts_feed" => "#{server_url}/posts",
            "new_post" => "#{server_url}/posts",
            "post" => "#{server_url}/posts/{entity}/{post}",
            "post_attachment" => "#{server_url}/posts/{entity}/{post}/attachments/{name}?version={version}",
            "batch" => "#{server_url}/batch",
            "server_info" => "#{server_url}/server"
          },
          "preference" => index
        }
      }
    }
  }
  let(:client_options) {
    {
      :server_meta => server_meta
    }
  }
  let(:client) { TentClient.new(entity_uri, client_options) }

  def expect_server(env, url)
    expect(env[:url].to_s).to match(url)
  end

  it 'proxies http verbs to Faraday' do
    cycle_http = described_class.new(client) do |f|
      f.adapter :test, http_stubs
    end

    post_entity = 'https://randomentity.example.org/xyz'
    post_id = 'someid'
    %w{ head get put patch post delete options }.each { |verb|
      http_stubs.send(verb, "/tent/posts/#{URI.encode_www_form_component(post_entity)}/#{post_id}") { |env|
        expect_server(env, server_urls.first)
        [200, {}, '']
      }

      expect(cycle_http).to respond_to(verb)
      cycle_http.send(verb, :post, :entity => post_entity, :post => post_id)
    }

    http_stubs.verify_stubbed_calls
  end

  it 'builds multipart requests' do
    cycle_http = described_class.new(client) do |f|
      f.adapter :net_http
    end

    http_stubs = []
    body = "--#{TentClient::MULTIPART_BOUNDARY}\r\nContent-Disposition: form-data; name=\"photos[0]\"; filename=\"foo.png\"\r\nContent-Length: 17\r\nContent-Type: image/png\r\nContent-Transfer-Encoding: binary\r\n\r\nFake photo data 1\r\n--#{TentClient::MULTIPART_BOUNDARY}\r\nContent-Disposition: form-data; name=\"photos[1]\"; filename=\"bar.png\"\r\nContent-Length: 17\r\nContent-Type: image/png\r\nContent-Transfer-Encoding: binary\r\n\r\nFake photo data 2\r\n--#{TentClient::MULTIPART_BOUNDARY}\r\nContent-Disposition: form-data; name=\"documentation\"; filename=\"README.txt\"\r\nContent-Length: 17\r\nContent-Type: text/plain\r\nContent-Transfer-Encoding: binary\r\n\r\nSome instructions\r\n--#{TentClient::MULTIPART_BOUNDARY}--\r\n\r\n"

    %w{ put patch post }.each { |verb|
      http_stubs << stub_request(verb.to_sym, "#{server_urls.first}/posts").with(
        :body => body,
        :header => {
          'Content-Type' => "#{TentClient::MULTIPART_CONTENT_TYPE};boundary=#{TentClient::MULTIPART_BOUNDARY}",
          'Content-Length' => body.length
        }
      )

      expect(cycle_http).to respond_to(:multipart_request)
      cycle_http.multipart_request(verb, :new_post, {}, [
        {
          :filename => 'foo.png',
          :content_type => 'image/png',
          :data => 'Fake photo data 1',
          :category => 'photos'
        },
        {
          :filename => 'bar.png',
          :content_type => 'image/png',
          :data => 'Fake photo data 2',
          :category => 'photos'
        },
        {
          :filename => 'README.txt',
          :content_type => 'text/plain',
          :data => 'Some instructions',
          :category => 'documentation'
        }
      ])
    }

    http_stubs.each do |stub|
      expect(stub).to have_been_requested
    end
  end

  it 'builds multipart requests with custom headers' do
    cycle_http = described_class.new(client) do |f|
      f.adapter :net_http
    end

    http_stubs = []
    body = "--#{TentClient::MULTIPART_BOUNDARY}\r\nContent-Disposition: form-data; name=\"photos\"; filename=\"foo.png\"\r\nContent-Length: 17\r\nContent-Type: image/vnd.foo.bar.v0+png\r\nContent-Transfer-Encoding: binary\r\nFoo: Bar\r\n\r\nFake photo data 1\r\n--#{TentClient::MULTIPART_BOUNDARY}--\r\n\r\n"

    %w{ put patch post }.each { |verb|
      http_stubs << stub_request(verb.to_sym, "#{server_urls.first}/posts").with(
        :body => body,
        :header => {
          'Content-Type' => "#{TentClient::MULTIPART_CONTENT_TYPE};boundary=#{TentClient::MULTIPART_BOUNDARY}",
          'Content-Length' => body.length
        }
      )

      expect(cycle_http).to respond_to(:multipart_request)
      cycle_http.multipart_request(verb, :new_post, {}, [
        {
          :filename => 'foo.png',
          :content_type => 'image/png',
          :data => 'Fake photo data 1',
          :category => 'photos',
          :headers => {
            'Content-Type' => "image/vnd.foo.bar.v0+png",
            'Foo' => 'Bar'
          }
        }
      ])
    }

    http_stubs.each do |stub|
      expect(stub).to have_been_requested
    end
  end

  it 'retries http with next server url' do
    http_stubs.get('/tent/posts') { |env|
      expect_server(env, server_urls.first)
      [500, {}, '']
    }

    http_stubs.get('/tent/posts') { |env|
      expect_server(env, server_urls[1])
      [300, {}, '']
    }

    http_stubs.get('/tent/posts') { |env|
      expect_server(env, server_urls.last)
      [200, {}, '']
    }

    cycle_http = described_class.new(client) do |f|
      f.adapter :test, http_stubs
    end

    cycle_http.get(:new_post)

    http_stubs.verify_stubbed_calls
  end

  it 'returns response when on last server url' do
    http_stubs.get('/tent/posts') { |env|
      expect_server(env, server_urls.first)
      raise Faraday::Error::TimeoutError.new("")
    }

    http_stubs.get('/tent/posts') { |env|
      expect_server(env, server_urls[1])
      raise Faraday::Error::ConnectionFailed.new("")
    }

    http_stubs.get('/tent/posts') { |env|
      expect_server(env, server_urls.last)
      [300, {}, '']
    }

    http_stubs.get('/tent/posts') { |env|
      raise StandardError, 'expected stub not be called bus was'
    }

    cycle_http = described_class.new(client) do |f|
      f.adapter :test, http_stubs
    end

    cycle_http.get(:new_post)
  end
end
