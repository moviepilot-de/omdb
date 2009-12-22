module OMDB
  module Controller
    module SearchController
      
      def self.included(base) # :nodoc:
        base.extend SearchController
      end
      
      # == autocomplete_for
      # 
      # Mixin method to define autocomplete methods for
      # drop-down-menu selections. The method expects
      # a param[:model] with the search terms.
      #
      # You can pass a number of options:
      #   :limit          - number of results to be returned 
      #                     (defaults to 25)
      #   :offset         - the offset, where to start the search
      #                     (defaults to 0)
      #   :allow_creation - all the creation of new objects of this
      #                     type (defaults to false)
      #
      # This method expects a partial called _autocomplete.rhtml in
      # views/#{model}/search, that will be used for rendering the
      # autocomplete LI-entry.
      
      def autocomplete_for( models, opts = {} )
        models.each do |model|
          options = { :limit  => 25, :offset => 0, :allow_creation => false, 
                      :class  => model.to_s.camelize,
                      :method => :search_by_prefix }.merge( opts )
          method_name = "#{model}_autocomplete"
          verify :method => :post, :only => method_name
          verify :param => model, :only => method_name
          verify :xhr => true, :only => method_name
          
          define_method( method_name ) do
            @model          = options[:class].underscore
            @filter         = params[model]
            @allow_creation = options[:allow_creation]
            
            respond_to do |type|
              type.html { render :nothing => true }
              type.js do
                # render default 'enter search term' dialog, if
                # not enough characters entered.
                render :action => 'enter_search_term' if @filter.length < 2
                
                # start the default search for autocomplete actions
                @results = options[:class].constantize.send( options[:method], 
                             @filter, @language, options[:offset], options[:limit] )
                render :action => 'autocomplete'
              end
            end
          end          
        end
      end

    end
  end
end