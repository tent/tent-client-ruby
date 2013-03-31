class TentClient
  class Post
    attr_reader :client
    def initialize(client)
      @client = client
    end

    def create(data, params = {})
      client.http.post(:new_post, params, data)
    end
  end
end
