class MovieUserCategoryLogObserver < ActionController::Caching::Sweeper
  observe MovieUserCategory
  
  def after_create( muc )
    if MovieUserCategory.find_votes_for_movie(muc.movie, muc.category) == 1
      muc.movie.log_entries << AssocLogEntry.new( :user => muc.user, :ip_address => current_user.ip_address,
                                :new_value => muc.category.id, :old_value => nil, :attribute => Category.to_s.underscore ) unless current_user.nil?
    end
  end
  
  def after_destroy( muc )
    if MovieUserCategory.find_votes_for_movie(muc.movie, muc.category) == 0
      muc.movie.log_entries << AssocLogEntry.new( :user => muc.user, :ip_address => current_user.ip_address,
                                :new_value => nil, :old_value => muc.category.id, :attribute => Category.to_s.underscore ) unless current_user.nil?
    end
  end
end
