class TentClient
  class Following
    def initialize(client)
      @client = client
    end

    def list(params = {})
      @client.http.get '/followings', params
    end

    def create(entity_uri)
      @client.http.post '/followings', :entity => entity_uri.sub(%r{/$}, '')
    end

    def get(id)
      @client.http.get "/followings/#{id}"
    end

    def delete(id)
      @client.http.delete "/followings/#{id}"
    end
  end
end
