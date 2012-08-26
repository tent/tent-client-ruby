require 'spec_helper'

describe TentClient::Discovery do
  def stub_http_requests(&block)
    TentClient.stubs(:http).returns Faraday.new { |b| b.adapter :test, &block }
  end


  it 'should discover profile urls via a link header' do
    stub_http_requests do |s|
      s.head('/') { [200, { 'Link' => %Q(<https://example.com/tent/profile>; rel="profile"; type="application/vnd.tent.profile+json") }, ''] }
    end

    discovery = described_class.new('http://example.com/')
    discovery.perform.should eq(['https://example.com/tent/profile'])
  end
end
