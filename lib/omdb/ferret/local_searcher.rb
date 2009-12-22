# wird nur fuer tests verwendet, ansonsten macht der indexer_worker diesen Job
module OMDB
  module Ferret
    class LocalSearcher
      include LocalSearch
      include SimilarMovies
      include Singleton
      
      @@last_switch = Time.now

      LOGGER = Logger.new("#{RAILS_ROOT}/log/searcher.log") if defined? RAILS_ROOT

      def initialize
        reload_ram_directory
      end

      def index
        if switched? or @searcher.nil?
          reload_ram_directory
        end
        @searcher
      end

      def real_search(query, options)
        return if query.blank?
        returning result = [] do
          index.search_each( query, options ) do |id, score|
            result << index[id]
          end
        end
      end
      
      def explain( query, options )
        index.search_each( query, options ) do |id, score|
          puts "----------------------------------"
          puts index.explain( query, id ).to_s
        end
      end

      def hit_count(query)
        index.search(query).total_hits
      end
      
      # (re)open the ram index mirror used for searching
      def reload_ram_directory
        @searcher.close if @searcher
        @searcher = ::Ferret::Index::Index.new(:dir => Indexer.index_root, :analyzer => Indexer.get_analyzer)
        LOGGER.debug "re-opened ram directory"
        # ram_directory = ::Ferret::Store::RAMDirectory.new Indexer.index_root
        # @ram_directory.close if @ram_directory
        # @ram_directory = ram_directory
      rescue
        LOGGER.error "caught error in reload_ram_directory: #{$!}\n#{$!.backtrace.join "\n"}"
      end
      
      def switched?
        time = File.mtime( Indexer.index_status_file )
        if time > @@last_switch
          @@last_switch = time
          true
        else
          false
        end
      end
      
      def reload!
        close!
      end
      
      def close!
        @searcher.close if @searcher
        @searcher = nil
        GC.start
      end
    end
  end
end
