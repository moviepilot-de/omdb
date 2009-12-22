module CastHelper
  def actor_has_alias
    return false
  end

  def new_crew_link( movie )
    link_to_remote "add crew member".t, 
        { :update => 'new-crew', :url => { :controller => 'cast', :action => :new, :movie => movie.id } }, :class => 'edit-button'
  end
  
  def new_cast_link( movie )
    link_to_remote "add actor".t, 
        { :update => 'new-cast', :url => { :controller => 'cast', :action => :new_cast, :movie => movie.id } }, :class => 'edit-button'
  end
  
end
