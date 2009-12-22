module OMDB
  module Ferret
    class FerretPaginator
      # :TODO: The searcher should return paginated results, not the
      # search controller
      def self.find_paginated( options )
        options.reverse_merge!( :language  => Locale.base_language.code,
                                :current   => 1,
                                :page_size => 24 )

        PagingEnumerator.new( options[:page_size], options[:hits], false, options[:current], 1 ) do
          current = options[:current] && options[:current].to_i > 0 ? options[:current] : 1
          offset = (options[:current].to_i - 1) * options[:page_size]
          LocalSearcher.instance.real_search( options[:query], :limit => options[:page_size], :offset => offset, :order => options[:order], :filter => options[:filter] )
        end
      end
    end
  end
end