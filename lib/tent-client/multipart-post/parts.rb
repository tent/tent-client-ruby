# Modified version of https://github.com/nicksieger/multipart-post/blob/7d8b74888bf13f702a9590212533f869f0f43f64/lib/parts.rb

require 'parts'

module Parts
  module Part #:nodoc:
    def self.new(boundary, name, value, options = {})
      if value.respond_to?(:content_type)
        FilePart.new(boundary, name, value, options)
      else
        ParamPart.new(boundary, name, value, options)
      end
    end

    def length
      @part.length
    end

    def to_io
      @io
    end
  end

  class ParamPart
    include Part
    def initialize(boundary, name, value, options = {})
      @part = build_part(boundary, name, value, options)
      @io = StringIO.new(@part)
    end

    def length
     @part.bytesize
    end

    def build_part(boundary, name, value, options = {})
      part = []
      part << "--#{boundary}"
      part << %(Content-Disposition: form-data; name="#{name.to_s}")

      (options[:headers] || {}).each do |name, value|
        part << "#{name}: #{value}"
      end

      part.join("\r\n") << "\r\n\r\n"
      part << "#{value}\r\n"
    end
  end

  # Represents a part to be filled from file IO.
  class FilePart
    include Part
    attr_reader :length
    def initialize(boundary, name, io, options = {})
      file_length = io.respond_to?(:length) ?  io.length : File.size(io.local_path)

      options ||= {}
      options.merge!(
        :io_opts => io.respond_to?(:opts) ? io.opts : {}
      )

      @head = build_head(boundary, name, io.original_filename, io.content_type, file_length, options)
      @foot = "\r\n"
      @length = @head.length + file_length + @foot.length
      @io = CompositeReadIO.new(StringIO.new(@head), io, StringIO.new(@foot))
    end

    def build_head(boundary, name, filename, type, content_len, options = {})
      io_opts = options[:io_opts]
      trans_encoding = io_opts["Content-Transfer-Encoding"] || "binary"
      content_disposition = io_opts["Content-Disposition"] || "form-data"

      options[:headers] ||= {}

      part = []
      part << "--#{boundary}"
      part << %(Content-Disposition: #{content_disposition}; name="#{name.to_s}"; filename="#{filename}")
      part << "Content-Length: #{content_len}"
      if content_id = io_opts["Content-ID"]
        part << "Content-ID: #{content_id}"
      end
      part << "Content-Type: #{options[:headers].delete('Content-Type') || type}"
      part << "Content-Transfer-Encoding: #{trans_encoding}"

      options[:headers].each do |name, value|
        part << "#{name}: #{value}"
      end

      part.join("\r\n") + "\r\n\r\n"
    end
  end

  # Represents the epilogue or closing boundary.
  class EpiloguePart
    include Part
    def initialize(boundary)
      @part = "--#{boundary}--\r\n\r\n"
      @io = StringIO.new(@part)
    end
  end
end
