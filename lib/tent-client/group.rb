class TentClient
  class Group
    def initialize(client)
      @client = client
    end

    def get(id)
      @client.http.get("groups/#{id}")
    end

    def update(id, data)
      @client.http.put("groups/#{id}", data)
    end

    def count(params={})
      @client.http.get('groups/count', params)
    end

    def list(params={})
      @client.http.get('groups', params)
    end

    def create(data)
      @client.http.post('groups', data)
    end

    def delete(id)
      @client.http.delete("groups/#{id}")
    end
  end
end
