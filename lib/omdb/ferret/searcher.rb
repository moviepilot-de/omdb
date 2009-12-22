require 'lazy_doc'
require 'remote_searcher'
require 'local_searcher'

# Interface to search
# This class is only a proxy that decides if a local or a remote searcher
# should be used.
module OMDB
  module Ferret
    class Searcher

      class << self
        def searcher
          @@searcher ||= LocalSearcher.instance
        end

        def method_missing(method, *args)
          searcher.send method, *args
        end
      end
      
    end
    
    class Indexer
      class << self
        def indexer
          @@indexer ||= (RAILS_ENV == 'test' ? LocalIndexer : RemoteIndexer).new
        end

        def method_missing(method, *args)
          indexer.send method, *args
        end
      end
    end
  end
end
