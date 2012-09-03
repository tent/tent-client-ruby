class TentClient
  class Post
    def initialize(client)
      @client = client
    end

    def create(post, options={})
      @client.http.post(options[:url] || '/posts', post)
    end
  end
end
