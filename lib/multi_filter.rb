# A MultiFilter is used to filter search results based on multiple values.
# Filters are added just like they would be to a Hash object.
#
# == Example
#
#   mf = MultiFilter.new
#   mf[:category] = category_filter
#   mf[:country] = country_filter
#
#   # run the query with the filter
#   index.search(query, :filter => mf)
#
#   # filters can be changed and deleted
#   mf[:category] = new_category_filter
#   mf.delete(:country)
#   index.search(query, :filter => mf)
#
class MultiFilter < Hash
  def bits(index_reader)
    bit_vector = Ferret::Utils::BitVector.new.not!
    filters = self.values
    filters.each {|filter| bit_vector.and!(filter.bits(index_reader))}
    bit_vector
  end
end
