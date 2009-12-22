module Freezable

  def self.included(base) # :nodoc:
    base.extend Freezable
  end

  def frozen?
    self.attribute_frozen? :self
  end

  def set_frozen
    self.freezable_attribute :self
  end

  def unfreeze
    self.unfreeze_attribute :self
  end

  def freezable?
    freezable_attribute? :self
  end

  def freeze_attribute( attribute )
    if attribute_freezable?( attribute ) and not attribute_frozen?( attribute )
      connection.execute(
        ActiveRecord::Base.send(:sanitize_sql, 
            [ "INSERT into frozen_attributes VALUES (?, ?, ?)", 
                self.class.base_class.to_s, id, attribute ])
      )
    end
  end

  def unfreeze_attribute( attribute )
    if attribute_freezable?( attribute ) and attribute_frozen?( attribute )
      connection.execute(
        ActiveRecord::Base.send(:sanitize_sql, 
            [ "DELETE from frozen_attributes WHERE object_type = ? AND 
                object_id = ? AND attribute = ?", 
                  self.class.base_class.to_s, id, attribute ])
      )
    end
  end

  def attribute_frozen?( attribute )
    if attribute_freezable?( attribute )
      result = connection.execute(
        ActiveRecord::Base.send(:sanitize_sql,
           [ "SELECT * from frozen_attributes WHERE object_type = ? AND
               object_id = ? AND attribute = ?", 
                 self.class.base_class.to_s, id, attribute ])
      )
      (result.num_rows == 0) ? false : true
    else
      return false
    end
  end

  def attribute_freezable?( attribute )
    @@freezable_attributes.include? attribute

  end

  def freezable_attribute( attribute )
    @@freezable_attributes = [] unless defined? @@freezable_attributes
    @@freezable_attributes.push( attribute ) unless @@freezable_attributes.include?( attribute )
  end

end
