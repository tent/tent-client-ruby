class TentClient
  class Follower
    def initialize(client)
      @client = client
    end

    def create(data)
      @client.http.post 'followers', data
    end

    def list(params = {})
      @client.http.get "followers", params
    end

    def get(id)
      @client.http.get "followers/#{id}"
    end

    def update(id, data)
      @client.http.put "followers/#{id}", data
    end

    def delete(id)
      @client.http.delete "followers/#{id}"
    end

    def challenge(path)
      str = SecureRandom.hex(32)
      res = @client.http.get(path.sub(%r{\A/}, ''), :challenge => str)
      res.status == 200 && res.body.match(/\A#{str}/)
    end
  end
end
