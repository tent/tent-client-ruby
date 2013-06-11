class TentClient
  class Post
    attr_reader :client
    def initialize(client)
      @client = client
    end

    def get(entity, post_id, params = {}, &block)
      client.http.get(:post, { :entity => entity, :post => post_id }.merge(params), &block)
    end

    def list(params = {}, &block)
      client.http.get(:posts_feed, params, &block)
    end

    def create(data, params = {}, options = {}, &block)
      new_block = proc do |request|
        request.options['tent.notification'] = options.delete(:notification)
        yield(request) if block_given?
      end

      if (Array === (attachments = options.delete(:attachments))) && attachments.any?
        parts = multipart_parts(data, attachments)
        client.http.multipart_request(:post, :new_post, params, parts, &new_block)
      else
        client.http.post(:new_post, params, data, &new_block)
      end
    end

    def update(entity, post_id, data, params = {}, options = {}, &block)
      params = { :entity => entity, :post => post_id }.merge(params)
      if (Array === (attachments = options.delete(:attachments))) && attachments.any?
        parts = multipart_parts(data, attachments)
        client.http.multipart_request(:put, :post, params, parts, &block)
      else
        client.http.put(:post, params, data, &block)
      end
    end

    def mentions(entity, post_id, params = {}, options = {}, &block)
      # TODO: handle options[:page] => :first || :last || page-id

      params = { :entity => entity, :post => post_id }.merge(params)

      new_block = proc do |request|
        request.headers['Accept'] = POST_MENTIONS_CONTENT_TYPE
        yield(request) if block_given?
      end

      client.http.get(:post, params, &new_block)
    end

    def versions(entity, post_id, params = {}, options = {}, &block)
      # TODO: handle options[:page] => :first || :last || page-id

      params = { :entity => entity, :post => post_id }.merge(params)

      new_block = proc do |request|
        request.headers['Accept'] = POST_VERSIONS_CONTENT_TYPE
        yield(request) if block_given?
      end

      client.http.get(:post, params, &new_block)
    end

    def children(entity, post_id, params = {}, options = {}, &block)
      # TODO: handle options[:page] => :first || :last || page-id

      params = { :entity => entity, :post => post_id }.merge(params)

      new_block = proc do |request|
        request.headers['Accept'] = POST_CHILDREN_CONTENT_TYPE
        yield(request) if block_given?
      end

      client.http.get(:post, params, &new_block)
    end

    private

    def multipart_parts(data, attachments)
      [data_as_attachment(data)] + attachments.map { |a|
        a[:filename] = a.delete(:name) || a.delete('name')
        a[:headers] = {
          'Attachment-Digest' => client.hex_digest(a[:data] || a[:data])
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
