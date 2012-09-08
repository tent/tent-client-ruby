class TentClient
  class AppAuthorization
    attr_accessor :client

    def initialize(client)
      @client = client
    end

    def create(app_id, data)
      @client.http.post("apps/#{app_id}/authorizations", data)
    end

    def update(app_id, id, data)
      @client.http.put("apps/#{app_id}/authorizations/#{id}", data)
    end

    def delete(app_id, id)
      @client.http.delete("apps/#{app_id}/authorizations/#{id}")
    end
  end
end
