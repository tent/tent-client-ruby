class TentClient
  class Profile
    attr_accessor :client

    def initialize(client)
      @client = client
    end

    def update(type, data)
      @client.http.put("/profile/#{URI.encode(type, ":/")}", data)
    end
  end
end
