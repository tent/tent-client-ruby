require 'spec_helper'


describe TentClient::Middleware::MacAuth do
  def auth_header(env)
    env[:request_headers]['Authorization']
  end

  def perform(path = '', method = :get, body = nil)
    make_app.call({
      :url => URI('http://example.com' + path),
      :method => method,
      :request_headers => {},
      :body => body
    })
  end

  def make_app
    described_class.new(lambda{ |env| env }, options)
  end

  context 'not configured' do
    let(:options) { {} }

    it "doesn't add a header" do
      auth_header(perform).should be_nil
    end
  end

  context 'configured' do
    let(:options) { { :mac_key_id => 'h480djs93hd8', :mac_key => '489dks293j39', :mac_algorithm => 'hmac-sha-1' } }
    let(:expected_header) { 'MAC id="h480djs93hd8", ts="1336363200", nonce="dj83hs9s", mac="%s"' }
    before do
      Time.expects(:now).returns(stub(:to_i => 1336363200))
      SecureRandom.expects(:hex).with(3).returns('dj83hs9s')
    end

    it 'signs a GET request with no body' do
      auth_header(perform('/resource/1?b=1&a=2')).should eq(expected_header % '6T3zZzy2Emppni6bzL7kdRxUWL4=')
    end

    it 'signs POST request with body' do
      auth_header(perform('/resource/1?b=1&a=2', :post, "asdf\nasdf")).should ==
        expected_header % 'SIBz/j9mI1Ba2Y+10wdwbQGv2Yk='
    end

    it 'signs POST request with a readable body' do
      io = StringIO.new("asdf\nasdf")
      auth_header(perform('/resource/1?b=1&a=2', :post, io)).should == 
        expected_header % 'SIBz/j9mI1Ba2Y+10wdwbQGv2Yk='
      io.eof?.should be_false
    end

    context 'SHA256' do
      let(:options) { { :mac_key_id => 'h480djs93hd8', :mac_key => '489dks293j39', :mac_algorithm => 'hmac-sha-256' } }
      it 'signs POST request with body using SHA256' do
        auth_header(perform('/resource/1?b=1&a=2', :post, "asdf\nasdf")).should ==
          expected_header % 'Xt51rtHY5F+jxKXMCoiKgXa3geofWW/7RANCXB1yu08='
      end
    end
  end

  context 'faraday middleware' do
    let(:options) { { :mac_key_id => 'h480djs93hd8', :mac_key => '489dks293j39', :mac_algorithm => 'hmac-sha-1' } }
    let(:http_stub) {
      Faraday::Adapter::Test::Stubs.new do |s|
        s.post('/') { [200, {}, ''] }
      end
    }
    let(:client) { TentClient.new('http://example.com', options.merge(:faraday_adapter => [:test, http_stub])) }

    it "should be part of the client middleware stack" do
      client.http.post('/', :foo => 'bar').env[:request_headers]['Authorization'].should =~ /\AMAC/
    end
  end
end
