module OMDB
  module Ferret
    class RemoteSearcher
      def initialize
        @searcher = MiddleMan.get_worker 'ferret_server'
      end

      def method_missing(method_name, *args)
        @searcher.send method_name, *args
      end
    end
  end
end