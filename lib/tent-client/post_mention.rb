class TentClient
  class PostMention
    def initialize(client)
      @client = client
    end

    def list(post_id, params = {})
      @client.http.get("/posts/#{post_id}/mentions", params)
    end
  end
end
