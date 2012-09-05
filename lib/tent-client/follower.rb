class TentClient
  class Follower
    def initialize(client)
      @client = client
    end

    def create(data)
      @client.http.post '/followers', data
    end

    def get(id)
      @client.http.get "/followers/#{id}"
    end
  end
end
