class TentClient
  class PostAttachment
    def initialize(client)
      @client = client
    end

    def get(post_id, filename, type)
      @client.http.get("posts/#{post_id}/attachments/#{filename}", {}, { 'Accept' => type })
    end
  end
end
