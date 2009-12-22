class GenericLogObserver < ActionController::Caching::Sweeper
  observe Category, Character, Company, Job, Person, Movie, Image
  
  def after_create( object )
    return if controller.nil?
    current_user = controller.send( :current_user )
    object.log_entries.create( :attribute => "self", :user => current_user, :ip_address => current_user.ip_address )
  end
  
  def after_update( object )
    object.write_log controller.send( :current_user ) unless controller.nil?
  end
end
