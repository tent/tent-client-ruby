require 'spec_helper'
require 'tent-client/discovery'

require 'support/discovery_link_behaviour'

describe TentClient::Discovery do
  let(:entity_uri) { "http://entity.example.org/xfapc" }
  let(:server_url) { "http://tent.example.org/xfapc" }
  let(:server_meta_post_url) { "#{server_url}/posts/29834719346" }
  let(:link_header) {
    %(<#{server_meta_post_url}>; rel="%s") % described_class::META_POST_REL
  }
  let(:link_html) {
    %(<html><head><link href="#{server_meta_post_url}" rel="%s" /></head></html>) % described_class::META_POST_REL
  }
  let(:meta_post) {
    {
      "entity" => entity_uri,
      "previous_entities" => [],
      "servers" => [
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
          "preference" => 0
        }
      ]
    }
  }
  let(:client) { TentClient.new(entity_uri) }
  let(:instance) { described_class.new(client, entity_uri) }

  describe ".discover" do
    it "performs discovery" do
      described_class.any_instance.expects(:discover)
      described_class.discover(client, entity_uri)
    end
  end

  describe "#discover" do
    context "when multiple links" do
      before do
        instance.expects(:perform_head_discovery).returns([
          "http://foo.example.com", server_meta_post_url
        ])

        stub_request(:any, "http://foo.example.com").to_return(:status => 404)
      end

      it_behaves_like "a valid discovery link"
    end

    context "when valid link header" do
      before do
        stub_request(:head, entity_uri).to_return(:headers => { 'Link' => link_header })
      end

      it_behaves_like "a valid discovery link"
    end

    context "when invalid link header" do
      before do
        stub_request(:head, entity_uri).to_return(:headers => { 'Link' => link_header })
      end

      it_behaves_like "a invalid discovery link"
    end

    context "when no link header" do
      before do
        stub_request(:head, entity_uri).to_return(:headers => { 'Link' => "" })
      end

      context "when valid link tag" do
        before do
          stub_request(:get, entity_uri).to_return(:body => link_html, :headers => { 'Content-Type' => 'text/html' })
        end

        it_behaves_like "a valid discovery link"
      end

      context "when no link tag" do
        before do
          stub_request(:get, entity_uri).to_return(:body => "<html></html>", :headers => { 'Content-Type' => 'text/html' })
        end

        it_behaves_like "a invalid discovery link"
      end

      context "when invalid link tag" do
        before do
          stub_request(:get, entity_uri).to_return(:body => link_html, :headers => { 'Content-Type' => 'text/html' })
        end

        it_behaves_like "a invalid discovery link"
      end
    end
  end
end
