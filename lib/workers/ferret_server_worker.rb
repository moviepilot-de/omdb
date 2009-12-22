# FerretServer
# 
# BackgroundRb Worker to serve as a ferret-server. All index and search requests
# will be forwarded to this server, where all indexing requests gets serialized.
#
# Author:: Benjamin Krause, Jens Kraemer
require 'lazy_doc'
require 'unique_queue'
require 'indexer'
require 'util'

module OMDB
  module Ferret
    class FerretServerWorker < BackgrounDRb::Rails
      include LocalSearch
      include OMDB::Util
      include FileUtils
      include MonitorMixin

      first_run Time.now.to_s(:db)

      # Neccessary to avaid 'hanging' sql connections
      ActiveRecord::Base.allow_concurrency = true
      ActiveRecord::Base.verification_timeout = 10

      private

      # Main Loop for the worker. The Worker gets autostarted by
      # backgroundrb and will then wait for entries in the 
      # queue. As soon as an entry is present, it will process
      # the record until the queue is empty again.
      # It'll optimize the Ferret Index, once the queue is empty.
      def do_work(args)
        initialize_server
        loop do
          @logger.info("starting loop...")
          counter = 1
          record = @queue.pop
          # open the offline-index
          Indexer.get_writer_and_optimize( true ) do |writer|
            benchmark("indexing took %s")  do
              @logger.info("opening writer")
              process_record( record, writer )
              # index until the queue is empty or we have indexed
              # 256 records ..
              while not @queue.empty? and counter < 256
                record = @queue.pop
                process_record( record, writer )
                counter = counter.succ
              end
            end
            @logger.info("closing writer after processing #{counter} records")
          end
          switch_index
        end
      rescue Exception
        @logger.error "caught fatal error in do_work, terminating: #{$!}\n#{$!.backtrace.join "\n"}"
      end

      public
      
      # == Indexing Methods
      # 
      # This are the main method called to modify the ferret index. All of these methods 
      # will be called by the SearchObserver, but you can use them on the console as well.
      #
      # >> MiddleMan.get_worker('ferret_server').index_object Person.find(123).to_hash_args
      #

      # Add object to the ferret index
      def index_object(args)
        @logger.info "received indexing request for #{args.inspect}"
        enqueue args, :add
      rescue
        @logger.error "caught error in index_object: #{$!}\n#{$!.backtrace.join "\n"}"
      end
      alias << index_object

      # Remove object from the ferret index
      def delete_object(args)
        @logger.info "received delete request for #{args.inspect}"
        enqueue args, :remove
      rescue
        @logger.error "caught error in delete: #{$!}\n#{$!.backtrace.join "\n"}"
      end
      alias delete delete_object
      alias - delete


      # === Index dependencies
      # 
      # after a record has been changed, a lot of other objects might 
      # need to be updated in the index as well. To get all depending objects,
      # omdb has several dependency-views in the database. 
      # This method will assure, that not only the object itself gets updated
      # in the index, but all dependent objects as well. 
      # Fetching all dependencies might take some time, so we create a new 
      # thread to fetch the dependencies and add them to the index queue
      #
      # :TODO: für extra Bonuspunkte die Queue double-ended machen und die records
      # unpoppen so dass die Reihenfolge erhalten bleibt :)
      def index_dependencies(args)
        Thread.new do
          @logger.info "enqueueing dependencies of #{args.inspect}"
          record = get_object args[:type], args[:id]
          if record
            objects = record.dependent_objects
            objects.each do |class_name, id_array|
              id_array.each do |id|
                next if id == 0
                index_object :type => class_name, :id => id
              end
            end
          else
            @logger.info "record #{args.inspect} not found, no dependencies enqueued"
          end
          record.class.connection.disconnect!
        end
      end

      # empties the queue and inserts a single :reindex action
      def rebuild_index
        @queue.clear
        enqueue({}, :reindex)
      rescue
        @logger.error "caught error in rebuild_index: #{$!}\n#{$!.backtrace.join "\n"}"
      end

      def status
        returning status = { :objects_in_queue => @queue.size } do
          if rebuilding?
            status[:reindexing_since]     = @reindexing_since
            status[:last_reindexing_time] = @last_reindexing_time
            status[:percentage]           = (Time.now - @reindexing_since)*100.0 / @last_reindexing_time if @last_reindexing_time
          end
        end
      rescue
        @logger.error "caught error in status: #{$!}\n#{$!.backtrace.join "\n"}"
      end

      def rebuilding?
        !@reindexing_since.nil?
      end


      protected
  
      # Initialize the Ferret Server by creating the UniqueQueue for indexing-requests,
      # loading the current index from disk to RAM and initializing the Server-Logfile
      def initialize_server
        @queue = UniqueQueue.new
        @logger.info "#{Time.now} initialized indexer worker in #{ENV['RAILS_ENV']} mode"
      end
      
      # === Process queue entries
      #
      # Main method to process the entries of the indexing queue. Each element in the 
      # queue consit of a class_name, an id and a action. We know three actions
      # for elements in the queue:
      # - add     : Add the class_name/id AR-object to the index (or update the object)
      # - remove  : Remove the class_name/id AR-object from the index
      # - reindex : Run a complete reindex, this can be triggered via the 
      #             admin/search_controller action :reindex.
      def process_record( record, writer )
        class_name, id, action = record
        begin
          case action
            when :add     : 
              object = get_object(class_name, id)
              @logger.info "indexing #{record.inspect}"
              Indexer.index_local( object, writer ) if object
            when :remove  : 
              @logger.info "deleting #{record.inspect}"
              Indexer.delete_local( { :type => class_name, :id => id }, writer )
            when :reindex :
              @logger.info "rebuilding the whole index"
              @reindexing_since = Time.now
              Indexer.reindex( writer )
              @last_reindexing_time = Time.now - @reindexing_since
              @reindexing_since = nil
            else raise 'unknown action'
          end
        rescue
          @logger.error "caught error inside loop: #{$!}\n#{$!.backtrace.join "\n"}"
        end
      end
  
      # Fetch the object from the database
      def get_object(class_name, id)
        begin
          clazz = class_name.constantize
          obj = clazz.find(id)
          @logger.info "fetched object #{obj.inspect}"
          return obj
        rescue ActiveRecord::RecordNotFound
          @logger.warn "#{Time.now} record not found: #{class_name} - #{id}, sleeping for a short while"
          sleep 3
          begin
            return clazz.find(id)
          rescue ActiveRecord::RecordNotFound
            @logger.error "still no luck with record: #{class_name} - #{id}, giving up :("
          end
        rescue ActiveRecord::StatementInvalid
          @logger.error "caught statement invalid: #{$!}\n#{$!.backtrace}\nforcing db reconnect and re-enqueueing object"
          clazz.connection.reconnect!
          # re-enqueue object
          enqueue({ :type => class_name, :id => id }, :add)
        end
        return nil
      end

      # Main method to add elements to the queue. @queue << will 
      # return false if the element is already in the queue,
      # avoiding unneccessary double-indexing.
      def enqueue(args, action)
        unless @queue << [ args[:type], args[:id], action ]
          @logger.debug "skipped enqueue, entry already present"
        end
      end
      
      def switch_index
        @logger.debug 'switching..'
        synchronize do
          relink
          sync
        end
      end
      
      def relink
        online  = File.readlink(Indexer.online_index)
        offline = File.readlink(Indexer.offline_index)
        File.delete Indexer.offline_index
        File.delete Indexer.online_index
        FileUtils.ln_s offline, Indexer.online_index, :force => true
        FileUtils.ln_s online,  Indexer.offline_index, :force => true
        # Inform the mongrel servers that a new index exists.
        FileUtils.touch Indexer.index_status_file
      end
      
      def sync
        @logger.info("syncing from #{Indexer.online_index}/ to #{Indexer.offline_index}")
        system("rsync -r --delete --verbose #{Indexer.online_index}/ #{Indexer.offline_index}")
      end
    end
  end
end
