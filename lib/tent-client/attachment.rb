class TentClient
  class Attachment
    attr_reader :client
    def initialize(client)
      @client = client
    end

    def get(entity, digest, params = {}, &block)
      client.http.get(:attachment, { :entity => entity, :digest => digest }.merge(params), &block)
    end
  end
end
