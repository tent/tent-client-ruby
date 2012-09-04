require 'spec_helper'

describe TentClient::Discovery do
  LINK_HEADER = %(<https://example.com/tent/profile>; rel="%s") % TentClient::PROFILE_REL
  LINK_TAG_HTML = %(<html><head><link href="https://example.com/tent/profile" rel="%s" /></head</html>) % TentClient::PROFILE_REL
  TENT_PROFILE = %({"https://tent.io/types/info/core/v0.1.0":{"licenses":["http://creativecommons.org/licenses/by/3.0/"],"entity":"https://example.com","servers":["https://example.com/tent"]}})

  let(:http_stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:client) { TentClient.new(nil, :faraday_adapter => [:test, http_stubs]) }

  it 'should discover profile urls via a link header' do
    http_stubs.head('/') { [200, { 'Link' => LINK_HEADER }, ''] }

    discovery = described_class.new(client, 'http://example.com/')
    discovery.perform.should eq(['https://example.com/tent/profile'])
  end

  it 'should discover profile urls via a link html tag' do
    http_stubs.head('/') { [200, { 'Content-Type' => 'text/html' }, ''] }
    http_stubs.get('/') { [200, { 'Content-Type' => 'text/html' }, LINK_TAG_HTML] }

    discovery = described_class.new(client, 'http://example.com/')
    discovery.perform.should eq(['https://example.com/tent/profile'])
  end

  it 'should work with relative urls' do
    http_stubs.head('/') { [200, { 'Link' => LINK_HEADER.sub(%r{https://example.com}, '') }, ''] }

    discovery = described_class.new(client, 'http://example.com/')
    discovery.perform.should eq(['http://example.com/tent/profile'])
  end

  it 'should fetch a profile' do
    http_stubs.head('/') { [200, { 'Link' => LINK_HEADER }, ''] }
    http_stubs.get('/tent/profile') { [200, { 'Content-Type' => TentClient::MEDIA_TYPE }, TENT_PROFILE] }
    discovery = described_class.new(client, 'http://example.com/')
    discovery.perform
    discovery.get_profile.should eq([JSON.parse(TENT_PROFILE), "https://example.com/tent"])
  end

  it 'should delegate TentClient.discover' do
    instance = mock(:perform => 1)
    described_class.expects(:new).with(client, 'url').returns(instance)
    client.discover('url').should eq(instance)
  end
end
