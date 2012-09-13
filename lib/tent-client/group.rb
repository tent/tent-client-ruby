class TentClient
  class Group
    def initialize(client)
      @client = client
    end

    def list
      @client.http.get('/groups')
    end

    def create(data)
      @client.http.post('/groups', data)
    end
  end
end
