class TentClient
  class Post
    attr_reader :client
    def initialize(client)
      @client = client
    end

    def create(data, params = {}, options = {}, &block)
      if attachments = options.delete(:attachments)
        parts = multipart_parts(data, attachments)
        client.http.multipart_request(:post, :new_post, params, parts, &block)
      else
        client.http.post(:new_post, params, data, &block)
      end
    end

    private

    def multipart_parts(data, attachments)
      [data_as_attachment(data)] + attachments.map { |a|
        a[:filename] = a.delete(:name) || a.delete('name')
        a[:headers] = {
          'Attachment-Hash' => client.hex_digest(a[:data] || a[:data])
        }.merge(a[:headers] || {})
        a
      }
    end

    def data_as_attachment(data)
      {
        :category => 'post',
        :filename => 'post.json',
        :content_type => POST_CONTENT_TYPE % (data[:type] || data['type']),
        :data => Yajl::Encoder.encode(data)
      }
    end
  end
end
