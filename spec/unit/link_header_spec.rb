require 'spec_helper'

describe TentClient::LinkHeader do
  def new_link(link, attrs={})
    TentClient::LinkHeader::Link.new(link, attrs)
  end
  it 'should parse a simple link' do
    link_header = %Q(<http://example.com/TheBook/chapter2>; rel="previous";\n    title="previous chapter")
    expected_link = new_link('http://example.com/TheBook/chapter2', :rel => 'previous', :title => 'previous chapter')
    described_class.parse(link_header).links.first.should eq(expected_link)
  end

  it 'should ignore utf-8 attributes' do
    link_header = %Q(</TheBook/chapter2>;\n rel="previous"; title*=UTF-8'de'letztes%20Kapitel,\n </TheBook/chapter4>;\n rel="next"; title*=UTF-8'de'n%c3%a4chstes%20Kapitel)
    expected_links = [new_link('/TheBook/chapter2', :rel => 'previous'), new_link('/TheBook/chapter4', :rel => 'next')]
    described_class.parse(link_header).links.should eq(expected_links)
  end

  it 'should convert a link header to a string' do
    expected_header = %Q(<https://example.com/tent/profile>; rel="profile"; type="application/vnd.tent.profile+json")
    link = new_link('https://example.com/tent/profile', :rel => 'profile', :type => 'application/vnd.tent.profile+json')
    described_class.new(link).to_s.should eq(expected_header)
  end
end
