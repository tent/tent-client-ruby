require 'uri'
require 'strscan'

class TentClient
  class LinkHeader
    attr_accessor :links

    def self.parse(header)
      new header.split(',').map { |l| Link.parse(l) }
    end

    def initialize(links)
      @links = Array(links)
    end

    def to_s
      links.map(&:to_s).join(', ')
    end

    class Link
      attr_accessor :uri, :attributes

      def self.parse(link_text)
        s = StringScanner.new(link_text)
        s.scan(/[^<]+/)
        link = s.scan(/<[^\s]+>/)
        link = link[1..-2]

        s.scan(/[^a-z]+/)
        attrs = {}
        while attr = s.scan(/[a-z0-9*\-]+=/)
          next if attr =~ /\*/
          val = s.scan(/".+?"|[^\s";]+/).sub(/\A"/, '').sub(/"\Z/, '')
          attrs[attr[0..-2]] = val
          s.scan(/[^a-z]+/)
        end
        new(link, attrs)
      end

      def initialize(uri, attributes = {})
        @uri = uri
        @attributes = indifferent_hash(attributes)
      end

      def ==(other)
        false unless is_a?(self.class)
        uri == other.uri && attributes == other.attributes
      end

      def [](k)
        attributes[k]
      end

      def []=(k, v)
        attributes[k.to_s] = v.to_s
      end

      def to_s
        attr_string = "; " + attributes.map { |k,v| "#{k}=#{v.inspect}" }.join('; ') if attributes
        "<#{uri}>#{attr_string}"
      end

      private

      def indifferent_hash(old_hash)
        new_hash = Hash.new {|hash,key| hash[key.to_s] if Symbol === key }
        old_hash.each { |k,v| new_hash[k.to_s] = v.to_s }
        new_hash
      end
    end
  end
end
