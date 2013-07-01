class TentClient
  class Attachment
    attr_reader :client
    def initialize(client)
      @client = client.dup
      @client.faraday_adapter = :net_http_stream
    end

    def get(entity, digest, params = {}, &block)
      client.http.get(:attachment, { :entity => entity, :digest => digest }.merge(params), &block)
    end
  end
end
