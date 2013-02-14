class TentClient
  class Following
    def initialize(client)
      @client = client
    end

    def count(params={})
      @client.http.get('followings/count', params)
    end

    def list(params = {})
      @client.http.get 'followings', params
    end

    def update(id, data)
      @client.http.put "followings/#{id}", data
    end

    def create(entity_uri, data = {})
      entity_uri, data = [entity_uri.delete(:entity), entity_uri] if entity_uri.kind_of?(Hash)
      @client.http.post('followings', data.merge(:entity => entity_uri.sub(%r{/$}, '')))
    end

    def get(id_or_entity, params={})
      @client.http.get "followings/#{URI.encode_www_form_component(id_or_entity)}", params
    end

    def proxy(id)
      TentClient.new(@client.server_urls.map { |url| "#{url}/followings/#{id}" }, @client.options)
    end

    def delete(id)
      @client.http.delete "followings/#{id}"
    end
  end
end
