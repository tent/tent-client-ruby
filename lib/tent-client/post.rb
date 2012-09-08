class TentClient
  class Post
    MULTIPART_TYPE = 'multipart/form-data'.freeze
    MULTIPART_BOUNDARY = "-----------TentAttachment".freeze

    def initialize(client)
      @client = client
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

    private

    def multipart_post(post, options, attachments)
      post_body = { :category => 'post', :filename => 'post.json', :type => MEDIA_TYPE, :data => post.to_json }
      body = multipart_body(attachments.unshift(post_body))
      @client.http.post(options[:url] || 'posts', body, 'Content-Type' => "#{MULTIPART_TYPE};boundary=#{MULTIPART_BOUNDARY}")
    end

    def multipart_body(attachments)
      parts = attachments.map do |attachment|
        Faraday::Parts::FilePart.new(MULTIPART_BOUNDARY, attachment[:category], attachment_io(attachment))
      end << Faraday::Parts::EpiloguePart.new(MULTIPART_BOUNDARY)
      Faraday::CompositeReadIO.new(parts)
    end

    def attachment_io(attachment)
      Faraday::UploadIO.new(attachment[:file] || StringIO.new(attachment[:data]), attachment[:type], attachment[:filename])
    end
  end
end
