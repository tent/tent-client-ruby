shared_examples "a valid discovery link" do
  before do
    stub_request(:any, server_host + server_meta_post_url).to_return(
      :status => 200,
      :headers => {
        'Content-Type' => 'application/json'
      },
      :body => Yajl::Encoder.encode(meta_post)
    )
  end

  it "returns meta post" do
    expect(instance.discover).to eql(meta_post)
  end
end

shared_examples "a invalid discovery link" do
  before do
    stub_request(:any, server_host + server_meta_post_url).to_return(
      :status => 404,
      :headers => {
        'Content-Type' => 'application/json'
      },
      :body => %({"error":"Not Found"})
    )
  end

  it "returns nil" do
    expect(instance.discover).to eql(nil)
  end
end
