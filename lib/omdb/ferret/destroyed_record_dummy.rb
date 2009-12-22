module OMDB
  module Ferret
    class DestroyedRecordDummy
      include Singleton
      def method_missing(*args)
        "record deleted"
      end
      def image
        nil
      end
      def jobs; [] end
    end
  end
end

