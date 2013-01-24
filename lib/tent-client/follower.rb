class TentClient
  class Follower
    def initialize(client)
      @client = client
    end

    def create(data)
      @client.http.post 'followers', data
    end

    def count(params={})
      @client.http.get('followers/count', params)
    end

    def list(params = {})
      @client.http.get "followers", params
    end

    def get(id_or_entity)
      @client.http.get "followers/#{URI.encode_www_form_component(id_or_entity)}"
    end

    def update(id, data)
      @client.http.put "followers/#{id}", data
    end

    def delete(id)
      @client.http.delete "followers/#{id}"
    end

    def challenge(path)
      str = SecureRandom.hex(32)
      res = @client.http.get(path.sub(%r{\A/}, '')) do |req|
        req.params['challenge'] = str
        req.headers['Accept'] = 'text/plain'
      end
      res.status == 200 && res.body.match(/\A#{str}/)
    end
  end
end
