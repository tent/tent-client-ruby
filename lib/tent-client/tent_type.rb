require 'uri'

class TentClient
  class TentType
    attr_accessor :base, :version, :fragment
    def initialize(uri = nil)
      @version = 0
      parse_uri(uri) if uri
    end

    def has_fragment?
      !!@fragment_separator
    end

    def fragment=(new_fragment)
      @fragment_separator = "#"
      @fragment = new_fragment
      @fragment = decode_fragment(@fragment) if @fragment
      @fragment
    end

    def to_s(options = {})
      options[:encode_fragment] = true unless options.has_key?(:encode_fragment)
      if (!has_fragment? && options[:fragment] != true) || options[:fragment] == false
        "#{base}/v#{version}"
      else
        "#{base}/v#{version}##{options[:encode_fragment] ? encode_fragment(fragment) : fragment}"
      end
    end

    def ==(other)
      unless TentType === other
        if String === other
          other = TentType.new(other)
        else
          return false
        end
      end

      base == other.base && version == other.version && has_fragment? == other.has_fragment? && fragment == other.fragment
    end

    private

    def parse_uri(uri)
      if m = %r{\A(.+?)/v(\d+)(#(.+)?)?\Z}.match(uri.to_s)
        m, @base, @version, @fragment_separator, @fragment = m.to_a
        @fragment = decode_fragment(@fragment) if @fragment
        @version = @version.to_i
      end
    end

    def decode_fragment(fragment)
      return unless fragment
      f, *r = URI.decode(fragment).split('#')
      ([f] + r.map { |_f| decode_fragment(_f) }).join('#')
    end

    def encode_fragment(fragment)
      return unless fragment
      parts = fragment.split('#')
      parts.reverse.inject(nil) { |m, _p| URI.encode("#{_p}#{m ? '#' + m : ''}") }
    end
  end
end
