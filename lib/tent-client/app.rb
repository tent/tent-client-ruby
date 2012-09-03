class TentClient
  class App
    attr_accessor :client

    def initialize(client)
      @client = client
    end

    def find(id)
      @client.http.get("/apps/#{id}")
    end

    def authorization
      AppAuthorization.new(@client)
    end
  end
end
