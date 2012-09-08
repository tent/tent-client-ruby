class TentClient
  class Post
    def initialize(client)
      @client = client
    end

    def list(params = {})
      @client.http.get('posts', params)
    end

    def create(post, options={})
      @client.http.post(options[:url] || 'posts', post)
    end

    def get(id)
      @client.http.get("posts/#{id}")
    end
  end
end
