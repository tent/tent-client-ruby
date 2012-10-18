class TentClient
  class Group
    def initialize(client)
      @client = client
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
  end
end
