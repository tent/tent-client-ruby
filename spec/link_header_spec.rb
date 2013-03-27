require 'spec_helper'
require 'tent-client/link_header'

describe TentClient::LinkHeader do
  def new_link(link, attrs={})
    TentClient::LinkHeader::Link.new(link, attrs)
  end

  it 'parses a simple link' do
    link_header = %Q(<http://example.com/TheBook/chapter2>; rel="previous";\n    title="previous chapter")
    expected_link = new_link('http://example.com/TheBook/chapter2', :rel => 'previous', :title => 'previous chapter')
    expect(described_class.parse(link_header).links.first).to eq(expected_link)
  end

  it 'ignores utf-8 attributes' do
    link_header = %Q(</TheBook/chapter2>;\n rel="previous"; title*=UTF-8'de'letztes%20Kapitel,\n </TheBook/chapter4>;\n rel="next"; title*=UTF-8'de'n%c3%a4chstes%20Kapitel)
    expected_links = [new_link('/TheBook/chapter2', :rel => 'previous'), new_link('/TheBook/chapter4', :rel => 'next')]
    expect(described_class.parse(link_header).links).to eq(expected_links)
  end

  it 'converts a link header to a string' do
    expected_header = %Q(<https://example.com/tent/profile>; rel="profile"; type="application/vnd.example.something+json")
    link = new_link('https://example.com/tent/profile', :rel => 'profile', :type => 'application/vnd.example.something+json')
    expect(described_class.new(link).to_s).to eq(expected_header)
  end
end
