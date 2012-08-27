class TentClient
  class Follower
    def initialize(client)
      @client = client
    end

    def create(data)
      @client.http.post '/followers', data
    end
  end
end
