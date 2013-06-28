class TentClient
  class Post
    attr_reader :client, :request_method
    def initialize(client, options = {})
      @client, @request_method = client, options.delete(:request_method)
    end

    def head
      self.class.new(client, :request_method => :head)
    end

    def get(entity, post_id, params = {}, &block)
      new_block = proc do |request|
        request.headers['Accept'] = POST_MEDIA_TYPE
        yield(request) if block_given?
      end

      client.http.send(request_method || :get, :post, { :entity => entity, :post => post_id }.merge(params), &new_block)
    end

    def get_attachment(entity, post_id, attachment_name, params = {}, &block)
      client.http.send(request_method || :get, :post_attachment, { :entity => entity, :post => post_id, :name => attachment_name }.merge(params), &block)
    end

    def delete(entity, post_id, params = {}, &block)
      client.http.delete(:post, { :entity => entity, :post => post_id }.merge(params), &block)
    end

    def list(params = {}, &block)
      client.http.send(request_method || :get, :posts_feed, params, &block)
    end

    def create(data, params = {}, options = {}, &block)
      if (Array === (attachments = options.delete(:attachments))) && attachments.any?
        parts = multipart_parts(data, attachments)
        client.http.multipart_request(:post, :new_post, params, parts, &block)
      else
        client.http.post(:new_post, params, data, &block)
      end
    end

    def update(entity, post_id, data, params = {}, options = {}, &block)
      params = { :entity => entity, :post => post_id }.merge(params)
      if (Array === (attachments = options.delete(:attachments))) && attachments.any?
        parts = multipart_parts(data, attachments, options)
        client.http.multipart_request(:put, :post, params, parts, &block)
      else
        new_block = proc do |request|
          if options.delete(:import)
            request.options['tent.import'] = true
          elsif options.delete(:notification)
            request.options['tent.notification'] = true
          end
          yield(request) if block_given?
        end

        client.http.put(:post, params, data, &new_block)
      end
    end

    def mentions(entity, post_id, params = {}, options = {}, &block)
      # TODO: handle options[:page] => :first || :last || page-id

      params = { :entity => entity, :post => post_id }.merge(params)

      new_block = proc do |request|
        request.headers['Accept'] = POST_MENTIONS_CONTENT_TYPE
        yield(request) if block_given?
      end

      client.http.send(request_method || :get, :post, params, &new_block)
    end

    def versions(entity, post_id, params = {}, options = {}, &block)
      # TODO: handle options[:page] => :first || :last || page-id

      params = { :entity => entity, :post => post_id }.merge(params)

      new_block = proc do |request|
        request.headers['Accept'] = POST_VERSIONS_CONTENT_TYPE
        yield(request) if block_given?
      end

      client.http.send(request_method || :get, :post, params, &new_block)
    end

    def children(entity, post_id, params = {}, options = {}, &block)
      # TODO: handle options[:page] => :first || :last || page-id

      params = { :entity => entity, :post => post_id }.merge(params)

      new_block = proc do |request|
        request.headers['Accept'] = POST_CHILDREN_CONTENT_TYPE
        yield(request) if block_given?
      end

      client.http.send(request_method || :get, :post, params, &new_block)
    end

    private

    def multipart_parts(data, attachments, options = {})
      [data_as_attachment(data, options)] + attachments.map { |a|
        a[:filename] = a.delete(:name) || a.delete('name')
        a[:headers] = a[:headers] || {}
        a
      }
    end

    def data_as_attachment(data, options = {})
      content_type = POST_CONTENT_TYPE % (data[:type] || data['type'])

      if options[:import]
        content_type << %(; rel="https://tent.io/rels/import")
      elsif options[:notification]
        content_type << %(; rel="https://tent.io/rels/notification")
      end

      {
        :category => 'post',
        :filename => 'post.json',
        :content_type => content_type,
        :data => Yajl::Encoder.encode(data)
      }
    end
  end
end
