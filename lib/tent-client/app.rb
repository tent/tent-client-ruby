class TentClient
  class App
    attr_accessor :client

    def initialize(client)
      @client = client
    end

    def create(data)
      @client.http.post("/apps", data)
    end

    def get(id)
      @client.http.get("/apps/#{id}")
    end

    def list(params = {})
      @client.http.get("/apps", params)
    end

    def delete(id)
      @client.http.delete("/apps/#{id}")
    end

    def update(id, data)
      @client.http.put("/apps/#{id}", data)
    end

    def authorization
      AppAuthorization.new(@client)
    end
  end
end
