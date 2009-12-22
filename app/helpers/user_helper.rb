module UserHelper
  def add_to_my_movies_url( movie, tag = ( params[:tag] || 'default') )
    { :controller => 'user', :action => :add_movie, :movie => movie.id, :tag => tag, :id => current_user.permalink }
  end

  def delete_from_my_movies_url( movie, tag = ( params[:tag] || 'default' ) )
    { :action => :delete_movie, :movie => movie.id, :tag => tag }
  end
  
  def created_movies( user )
    user.all_created_movies_paged.size
  end
  
  def movie_changes( user )
    LogEntry.count( [ "user_id = ? and related_object_type = 'Movie' and attribute != 'self'", user.id ])
  end
  
  def show_foto_foo
    return false
    @foto_foo and @user == current_user
  end
end
