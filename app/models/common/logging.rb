# thanks to Brandon Keepers, author of acts_as_audited

module Logging
  
  def self.included(base) # :nodoc:
    base.class_eval do
      cattr_accessor :non_loggable_columns, :logging_enabled
      self.non_loggable_columns = [self.primary_key, inheritance_column, 'lock_version', 'created_at', 'updated_at']

      has_many  :log_entries,
                :as => :related_object,
                :dependent => :destroy,
                :order => 'created_at DESC'

      def self.disable_logging_of( *attrs )
        attrs.each do |a|
          self.non_loggable_columns << a.to_s
        end
      end
    end
  end
  
  # If called with no parameters, gets whether the current model has changed.
  # If called with a single parameter, gets whether the parameter has changed.
  def changed?(attr_name = nil)
    @changed_attributes ||= {}
      attr_name.nil? ? !@changed_attributes.empty? : @changed_attributes.include?(attr_name.to_s)
  end
  
  def loggable_attributes
    self.attributes.keys.select { |k| !self.class.non_loggable_columns.include?(k) }
  end
  
  def write_log( user = User.anonymous )
    options = { :user => user, :ip_address => user.ip_address }
    @changed_attributes.each do |a, v|
      options[:attribute] = a
      options[:old_value] = v.first
      options[:new_value] = v.last
      if v.last.is_a?( Array )
        v.last.each do |value|
          options[:old_value] = nil
          options[:new_value] = value
          self.log_entries << AssocLogEntry.new( options ) unless value.nil?
        end
        v.first.each do |value|
          options[:new_value] = nil
          options[:old_value] = value
          self.log_entries << AssocLogEntry.new( options ) unless value.nil?
        end
      else
        self.log_entries.create options
      end
    end if @changed_attributes
  end
    
  def add_to_changed_attributes( attr_name, old_value, new_value )
    @changed_attributes ||= {}
    ov = []
    nv = []
    ov = @changed_attributes[attr_name].first if @changed_attributes[attr_name]
    nv = @changed_attributes[attr_name].last if @changed_attributes[attr_name]
    @changed_attributes[attr_name] = [ ov.push(old_value).uniq, nv.push(new_value).uniq ]
  end
  
  private
  
  # overload write_attribute to save changes to audited attributes
  def write_attribute(attr_name, attr_value)
    attr_name = attr_name.to_s
    if loggable_attributes.include?(attr_name)
      @changed_attributes ||= {}
      # get original value
      old_value = @changed_attributes[attr_name] ?
        @changed_attributes[attr_name].first : self[attr_name]
      super(attr_name, attr_value)
      new_value = self[attr_name]
      
      @changed_attributes[attr_name] = [old_value, new_value] if new_value != old_value
    else
      super(attr_name, attr_value)
    end
  end
  
  # clears current changed attributes.  Called after save.
  def clear_changed_attributes
    @changed_attributes = {}
  end
  
end
