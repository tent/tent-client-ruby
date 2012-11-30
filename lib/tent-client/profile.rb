class TentClient
  class Profile
    attr_accessor :client

    def initialize(client)
      @client = client
    end

    def update(type, data)
      @client.http.put "profile/#{URI.encode_www_form_component(type)}", data
    end

    def get
      @client.http.get 'profile'
    end

    def type
      ProfileType.new(@client)
    end
  end
end
