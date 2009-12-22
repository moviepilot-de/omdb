require 'set'

# Custom implementation of a Queue ensuring the uniqueness of it's contents.
# Elements that are already inside the queue will be rejected.
#
# Uniqueness is ensured with the help of a Set. To override Set's definition of
# equality, a proc taking the object to be placed in the queue as it's argument
# may be specified when creating the Queue. In this case, only the return value
# of this proc (and not the whole object) will be subject to the uniqueness
# checking in the Set.
#
# Note: For Arrays containing simple data types as String, Fixnum or Symbol no
# such special conversion proc needs to be given, but for Hashes you have to.

module OMDB
  module Ferret
    class UniqueQueue < Queue
  
      # make_comparable_proc can be used to transform objects into something comparable 
      # for doing the uniqueness checking
      def initialize(make_comparable_proc = nil)
        @set = Set.new
        @make_comparable_proc = make_comparable_proc
        super()
      end

      # Pushes +obj+ to the queue.
      # Will return true on success, and false if the
      # element is already present in the queue.
      def push(obj)
        Thread.critical = true
        key = make_comparable(obj)
        if is_new = !@set.include?(key)
          @que.push obj 
          @set << key
        end
        begin
          t = @waiting.shift
          t.wakeup if t
        rescue ThreadError
          retry
        ensure
          Thread.critical = false
        end
        begin
          t.run if t
        rescue ThreadError
        end
        is_new
      end

      alias << push
      alias enq push



      # Retrieves data from the queue.  If the queue is empty, the calling thread is
      # suspended until data is pushed onto the queue.  If +non_block+ is true, the
      # thread isn't suspended, and an exception is raised.
      def pop( non_blocking=false )
        while ( Thread.critical = true; @que.empty? )
          raise ThreadError, "queue empty" if non_blocking
          @waiting.push Thread.current
          Thread.stop
        end
        retval = @que.shift
        @set.delete make_comparable(retval)
        retval
      ensure
        Thread.critical = false
      end

      alias shift pop
      alias deq pop

      def clear
        Thread.critical = true
        super
        @set.clear
      ensure
        Thread.critical = false
      end

      private
      def make_comparable(obj)
        @make_comparable_proc.nil? ? obj : @make_comparable_proc.call(obj)
      end

    end
  end
end
