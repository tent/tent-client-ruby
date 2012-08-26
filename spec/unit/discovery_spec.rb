require 'spec_helper'

describe TentClient::Discovery do
  LINK_HEADER = %Q(<https://example.com/tent/profile>; rel="profile"; type="%s") % TentClient::PROFILE_MEDIA_TYPE
  LINK_TAG_HTML = %Q(<html><head><link href="https://example.com/tent/profile" rel="profile" type="%s" /></head</html>) % TentClient::PROFILE_MEDIA_TYPE
  def stub_http_requests(&block)
    TentClient.instance_variable_set('@http', nil)
    TentClient.stubs(:faraday_adapter).returns([:test, block])
  end

  it 'should discover profile urls via a link header' do
    stub_http_requests do |s|
      s.head('/') { [200, { 'Link' => LINK_HEADER }, ''] }
    end

    discovery = described_class.new('http://example.com/')
    discovery.perform.should eq(['https://example.com/tent/profile'])
  end

  it 'should discover profile urls via a link html tag' do
    stub_http_requests do |s|
      s.head('/') { [200, { 'Content-Type' => 'text/html' }, ''] }
      s.get('/') { [200, { 'Content-Type' => 'text/html' }, LINK_TAG_HTML] }
    end

    discovery = described_class.new('http://example.com/')
    discovery.perform.should eq(['https://example.com/tent/profile'])
  end

  it 'should delegate TentClient.discover' do
    instance = stub(:perform => 1)
    described_class.expects(:new).with('url').returns(instance)
    TentClient.discover('url').should eq(1)
  end
end
