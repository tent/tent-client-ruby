module Faraday
  module Utils
    class ParamsHash
      def to_query
        # Build params normally (e.g. a=1&a=2 rather than a[]=1&a[]=2)
        Utils.build_query(self)
      end
    end
  end
end
