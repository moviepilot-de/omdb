class CastLogObserver < ActionController::Caching::Sweeper
  observe Cast
  
  def after_create( cast )
    cast.movie.log_entries << CastLogEntry.new( :user => current_user, :ip_address => current_user.ip_address,
                                         :attribute => Cast.to_s.underscore, :old_value => nil, :new_value => [ cast.person.id, cast.job.id ].join(",") ) unless controller.nil?
  end
  
  def after_destroy( cast )
    cast.movie.log_entries << CastLogEntry.new( :user => current_user, :ip_address => current_user.ip_address,
                                         :attribute => Cast.to_s.underscore, :new_value => nil, :old_value => [ cast.person.id, cast.job.id ].join(",") ) unless controller.nil?
  end
end