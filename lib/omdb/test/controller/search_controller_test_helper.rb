module OMDB
  module Test
    module Controller
      module SearchControllerTestHelper
        
        def self.included(base) # :nodoc:
          base.extend SearchControllerTestHelper
        end
        
        def autocomplete_test_for( klass, id, string, opts = {} )
          options = { :fetch_method => klass.to_s.pluralize }
          options.update(opts)

          # Expecting to find certain livesearch entries in the response
          define_method( "test_autocomplete_for_#{klass.to_s}_#{id.to_s}" ) do
            #Indexer.index_all klass.to_s.camelize.constantize
            object = self.send(options[:fetch_method], id)

            xhr :post, "#{klass}_autocomplete", klass => string
            assert_success
            assert_tag 'li', :content => object.name
            yield self if block_given?
          end
          
          define_method( "test_autocomplete_nothing_found_for_#{klass.to_s}_#{id.to_s}" ) do
            xhr :post, "#{klass}_autocomplete", klass => (string * 12).reverse
            assert_success
            assert assigns(:results).empty?
            assert_tag 'li', :content => 'nothing found'
          end
        end
        
      end
    end
  end
end