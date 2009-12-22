class NameAliasLogObserver < ActionController::Caching::Sweeper
  observe NameAlias
  
  def after_create( name_alias )
    return if name_alias.related_object.class == Actor
    name_alias.related_object.log_entries.create :user => self.current_user, :ip_address => self.current_user.ip_address,
                      :attribute => 'name_alias', :old_value => nil, :new_value => name_alias.name, :language => name_alias.language unless controller.nil?
  end

  def after_update( name_alias )
    return if name_alias.related_object.class == Actor
    name_alias.write_log controller.send( :current_user ) unless controller.nil?
  end
  
  def after_destroy( name_alias )
    return if name_alias.related_object.class == Actor
    name_alias.related_object.log_entries.create :user => self.current_user, :ip_address => self.current_user.ip_address, 
                      :attribute => 'name_alias', :new_value => nil, :old_value => name_alias.name, :language => name_alias.language unless controller.nil?
  end
end