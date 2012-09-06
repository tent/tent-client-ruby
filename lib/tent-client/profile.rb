class TentClient
  class Profile
    attr_accessor :client

    def initialize(client)
      @client = client
    end

    def update(type, data)
      @client.http.put "/profile/#{URI.encode(type, ":/")}", data
    end

    def get
      @client.http.get '/profile'
    end
  end
end
