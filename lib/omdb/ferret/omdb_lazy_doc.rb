module OMDB
  module Ferret
    module OmdbLazyDoc

      def method_missing( method_name, *args )
        value = self[method_name]
        value.nil? ? to_o.send(method_name, *args ) : value
      end
      
      def to_o
        #self.class.find( self[:object_id].to_i )
        @record ||= self.class.find(self[:object_id].to_i)
      rescue ActiveRecord::RecordNotFound
        @record = DestroyedRecordDummy.instance
      end
      
      # Special treatment of the local_name mixin methods of AR-objects. Try to 
      # get the stored index data (like 'name_en') before asking the database.
      def local_name( lang = Locale.base_language )
        name = self["name_#{lang.code}".to_sym]
        name.nil? ? self.to_o.local_name( lang ) : name
      end
      
      def flattened_name( lang = Locale.base_language )
        name = self["hierarchy_#{lang.code}".to_sym]
        name.nil? ? self.to_o.flattened_name( lang ) : name
      end
      
      def parent
        parent_nil? ? nil : self.to_o.parent
      end
      
      def parent_nil?
        (self[:parent] == "false") ? true : false
      end
      
      def id
        self[:object_id].to_i
      end
      
      def assignable?
        (self[:is_assignable] == "false") ? false : true
      end
      
      def class
        (self[:type] == Movie.to_s.downcase) ? self[:movie_type].camelize.constantize : self[:type].camelize.constantize
      end
      
      def ==( other_object )
        ("#{self.class}:#{self.id}" == "#{other_object.class}:#{other_object.id}")
      end

    end
  end
end
