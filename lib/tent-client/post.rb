class TentClient
  class Post
    MULTIPART_TYPE = 'multipart/form-data'.freeze
    MULTIPART_BOUNDARY = "-----------TentAttachment".freeze

    def initialize(client)
      @client = client
    end

    def count(params={})
      @client.http.get('posts/count', params)
    end

    def list(params = {})
      @client.http.get('posts', params)
    end

    def create(post, options={})
      if options[:attachments]
        multipart_post(post, options, options.delete(:attachments))
      else
        @client.http.post(options[:url] || 'posts', post)
      end
    end

    def get(id)
      @client.http.get("posts/#{id}")
    end

    def delete(id)
      @client.http.delete("posts/#{id}")
    end

    def attachment
      PostAttachment.new(@client)
    end

    private

    def multipart_post(post, options, attachments)
      post_body = { :category => 'post', :filename => 'post.json', :type => MEDIA_TYPE, :data => post.to_json }
      body = multipart_body(attachments.unshift(post_body))
      @client.http.post(options[:url] || 'posts', body, 'Content-Type' => "#{MULTIPART_TYPE};boundary=#{MULTIPART_BOUNDARY}")
    end

    def multipart_body(attachments)
      parts = attachments.inject({}) { |h,a|
        (h[a[:category]] ||= []) << a; h
      }.inject([]) { |a,(category,attachments)|
        if attachments.size > 1
          a += attachments.each_with_index.map { |attachment,i|
            Faraday::Parts::FilePart.new(MULTIPART_BOUNDARY, "#{category}[#{i}]", attachment_io(attachment))
          }
        else
          a << Faraday::Parts::FilePart.new(MULTIPART_BOUNDARY, category, attachment_io(attachments.first))
        end
        a
      } << Faraday::Parts::EpiloguePart.new(MULTIPART_BOUNDARY)
      Faraday::CompositeReadIO.new(parts)
    end

    def attachment_io(attachment)
      Faraday::UploadIO.new(attachment[:file] || StringIO.new(attachment[:data]), attachment[:type], attachment[:filename])
    end
  end
end
