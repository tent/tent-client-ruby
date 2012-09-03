class TentClient
  class AppAuthorization
    attr_accessor :client

    def initialize(client)
      @client = client
    end

    def create(app_id, data)
      @client.http.post("/apps/#{app_id}/authorizations", data)
    end
  end
end
