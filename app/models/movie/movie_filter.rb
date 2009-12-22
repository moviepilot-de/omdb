require 'ferret'
require 'set'

# This class is a collection of movies on which filters can be applied. You
# can add and remove filters to narrow down your search. This class will also
# narrow down the options for live search fields. 
class MovieFilter
  include Ferret::Search
  ACCEPT_ALL_BITS = Ferret::Utils::BitVector.new.not!

  attr_reader :keywords
  def initialize
    @filter = MultiFilter.new
    @values = {}
    @keywords = Set.new
    Indexer::MOVIE_FILTER_FIELDS.each { |field|
      instance_variable_set("@#{field.to_s}_ids".to_sym, Set.new)
    }
  end

  Indexer::MOVIE_FILTER_FIELDS.each { |field|
    field = field.to_s
    attr_reader "#{field}_ids".to_sym
    class_eval <<-EOL
      def add_#{field}(obj)
        @#{field}_ids << obj.id
      end

      def delete_#{field}(obj)
        @#{field}_ids.delete(obj.id)
      end
      def add_#{field}_id(id)
        @#{field}_ids << id
      end

      def delete_#{field}_id(id)
        @#{field}_ids.delete(id)
      end
    EOL
  }

#  Not sure if this is really needed?  --benjamin
#
#  def add_keyword(keyword)
#    @keywords << keyword
#  end

#  def delete_keyword(keyword)
#    @keywords.delete(keyword)
#  end

  def bits(index_reader)
    q = BooleanQuery.new
    Indexer::MOVIE_FILTER_FIELDS.each { |field|
      field = field.to_s
      ids = instance_variable_get("@#{field}_ids".to_sym)
      ids.each {|id|
        q.add_query(TermQuery.new("#{field}_ids".to_sym, id.to_s), :must)
      }
    }
#    @keywords.each {|keyword|
#      q.add_query(TermQuery.new("keywords".to_sym, keyword.to_s), :must)
#    }
    if q.to_s.empty?
      ACCEPT_ALL_BITS
    else
      bits = QueryFilter.new(q).bits(index_reader)
    end
  end
end
