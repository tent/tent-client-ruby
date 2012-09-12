class TentClient
  class Group
    def initialize(client)
      @client = client
    end

    def list
      @client.http.get('/groups')
    end
  end
end
