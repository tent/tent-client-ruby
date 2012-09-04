class TentClient
  class App
    attr_accessor :client

    def initialize(client)
      @client = client
    end

    def create(data)
      @client.http.post("/apps", data)
    end

    def find(id)
      @client.http.get("/apps/#{id}")
    end

    def authorization
      AppAuthorization.new(@client)
    end
  end
end
