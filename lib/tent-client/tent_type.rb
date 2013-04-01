class TentClient
  class TentType
    attr_accessor :base, :version, :fragment
    def initialize(uri = nil)
      @version = 0
      parse_uri(uri) if uri
    end

    def to_s
      "#{base}/v#{version}##{fragment}"
    end

    private

    def parse_uri(uri)
      if m = %r{\A(.+)/v(\d+)(?:#(.+)?)?\Z}.match(uri.to_s)
        m, @base, @version, @fragment = m.to_a
        @version = @version.to_i
      end
    end
  end
end
