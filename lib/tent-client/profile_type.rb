class TentClient
  class ProfileType
    attr_accessor :client

    def initialize(client)
      @client = client
    end

    def get(type, params = {})
      @client.http.get "profile/#{URI.encode_www_form_component(type)}", params
    end

    def delete(type, params = {})
      @client.http.delete "profile/#{URI.encode_www_form_component(type)}", params
    end
  end
end
