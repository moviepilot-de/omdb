class AssocLogEntry < LogEntry
  
  def deletion?
    load_object.nil?
  end

  def load_object
    begin
      if self.new_value.nil?
        self.attribute.camelcase.constantize.find( self.old_value )
      else
        self.attribute.camelcase.constantize.find( self.new_value )
      end
    rescue
      # object gone?
      nil
    end
  end
end
