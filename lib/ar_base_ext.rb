module ActiveRecord
  class Base

    def base_class_name
      self.class.base_class_name
    end

    def self.base_class_name
      self.base_class.name.demodulize
    end
    
    # returns the model class directly below ActiveRecord::Base
    def toplevel_class
      self.class.base_class
    end
    # returns the model class directly below ActiveRecord::Base
    # TODO weghauen, durch base_class ersetzen
    def self.toplevel_class
      klazz = self
      while klazz.superclass != ActiveRecord::Base
        klazz = klazz.superclass 
      end
      return klazz
    end

    def self.reset_auto_increment
      connection.execute(
        "ALTER TABLE #{self.table_name} AUTO_INCREMENT = 0"
      )
    end

    def self.db_depending_objects
      class_name = self.base_class_name.downcase
      class_inheritable_accessor :skip_dependent_objects
      
      define_method :dependent_objects do
        row = connection.select_all( "select * from #{class_name}_dependencies_view where id=#{self.id}" ).first
        row.delete 'id' unless row.nil?
        returning({}) do |result|
          row.each do |key, ids|
            result[key] = ids.nil? ? [ 0 ] : ids.split(',').map(&:to_i)
          end unless row.nil?
          ( result[self.base_class_name] ||= [] ) << self.id
          if self.respond_to?(:children)
            result[self.base_class_name].concat self.all_children_ids
          end
          if self.respond_to?(:parent)
            result[self.base_class_name] << self.parent_id if self.parent_id
          end
        end
      end
    end

    def self.depending_objects( *method_names )
      class_inheritable_accessor :skip_dependent_objects

      define_method :dependent_objects do
        objects = []
        method_names.flatten.each do |m|
          if m == :self
            objects << self
          else
            objects << self.send(m)
          end
        end
        returning({}) do |result|
          objects.flatten.compact.uniq.each do |o|
            key = o.base_class_name
            result[key] ||= []
            result[key] << o.id
          end
        end
      end
    end

    def self.stub( attr_names, opts = {} )
      options = {
        :if    => :nil?,
        :clear => false
      }.merge( opts )
      self.stub_fields = options[:clear] ? {} : ( self.stub_fields ||= {} )
      attr_names.each do |attr|
        self.stub_fields[attr] = options
      end
    end
    
    def stub?
      return false if self.stub_fields.nil?
      self.stub_fields.each do |attr, options|
        return true if is_stub_field?( attr, options[:if] )
      end
      false
    end
    
    def active_stub_fields
      return false if self.stub_fields.nil?
      fields = []
      self.stub_fields.each do |attr, options|
        if is_stub_field?( attr, options[:if] )
          fields << attr
        end
      end
      fields
    end
    
    def self.controller_name
      base_class.name.underscore.gsub /.+\//, ''
    end

    def default_url(page = 'index')
      returning url = { :controller => self.class.controller_name, :id => self.id } do
        if page == 'index'
          url.merge! :action => 'index'
        else
          url.merge! :action => 'page', :page => page
        end
      end
    end

    def to_hash_args
      { :type => self.base_class_name, :id => self.id }
    end
    
    def to_o
      return self
    end

    private 
    
    def is_stub_field?( attr, check_method )
      value = self.send(attr)
      if check_method.is_a? Proc
        return true if check_method.call( value )
      else
        return true if value.send( check_method )
      end
      false
    end
  end
end
