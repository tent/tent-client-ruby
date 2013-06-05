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
    end

    def to_s(options = {})
      if (!has_fragment? && options[:fragment] != true) || options[:fragment] == false
        "#{base}/v#{version}"
      else
        "#{base}/v#{version}##{fragment}"
      end
    end

    private

    def parse_uri(uri)
      if m = %r{\A(.+)/v(\d+)(#(.+)?)?\Z}.match(uri.to_s)
        m, @base, @version, @fragment_separator, @fragment = m.to_a
        @version = @version.to_i
      end
    end
  end
end
