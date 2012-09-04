class TentClient
  class Following
    def initialize(client)
      @client = client
    end

    def create(entity_uri)
      @client.http.post '/followings', :entity => entity_uri.sub(%r{/$}, '')
    end
  end
end
