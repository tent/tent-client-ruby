class TentClient
  class PostVersion
    def initialize(client)
      @client = client
    end

    def list(post_id, params={})
      @client.http.get("posts/#{post_id}/versions", params)
    end
  end
end
