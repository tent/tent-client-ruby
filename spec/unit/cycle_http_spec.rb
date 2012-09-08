require 'spec_helper'

describe TentClient::CycleHTTP do

  let(:http_stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:client_options) { Hash.new }
  let(:server_urls) { %w{ http://alex.example.org http://alexsmith.example.com http://smith.example.com } }
  let(:client) { TentClient.new(server_urls, client_options) }

  def expect_server(env, url)
    expect(env[:url].to_s).to match(url)
  end

  it 'should proxy http verbs to Faraday' do
    http_stubs.get('/foo/bar') { |env = {}|
      expect_server(env, server_urls.first)
      [200, {}, '']
    }

    cycle_http = described_class.new(client) do |f|
      f.adapter :test, http_stubs
    end

    %w{ head get put patch post delete options }.each { |verb|
      expect(cycle_http).to respond_to(verb)
    }

    cycle_http.get('/foo/bar')

    http_stubs.verify_stubbed_calls
  end

  it 'should retry http with next server url' do
    http_stubs.get('/foo/bar') { |env = {}|
      expect_server(env, server_urls.first)
      [500, {}, '']
    }

    http_stubs.get('/foo/bar') { |env = {}|
      expect_server(env, server_urls[1])
      [300, {}, '']
    }

    http_stubs.get('/foo/bar') { |env = {}|
      expect_server(env, server_urls.last)
      [200, {}, '']
    }

    cycle_http = described_class.new(client) do |f|
      f.adapter :test, http_stubs
    end

    cycle_http.get('/foo/bar')

    http_stubs.verify_stubbed_calls
  end

  it 'should return response when on last server url' do
    http_stubs.get('/foo/bar') { |env = {}|
      expect_server(env, server_urls.first)
      [500, {}, '']
    }

    http_stubs.get('/foo/bar') { |env = {}|
      expect_server(env, server_urls[1])
      [500, {}, '']
    }

    http_stubs.get('/foo/bar') { |env = {}|
      expect_server(env, server_urls.last)
      [300, {}, '']
    }

    http_stubs.get('/foo/bar') { |env = {}|
      raise StandardError, 'expected stub not be called bus was'
    }

    cycle_http = described_class.new(client) do |f|
      f.adapter :test, http_stubs
    end

    cycle_http.get('/foo/bar')
  end
end
