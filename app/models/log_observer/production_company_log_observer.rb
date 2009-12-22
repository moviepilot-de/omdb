class ProductionCompanyLogObserver < ActionController::Caching::Sweeper
  observe ProductionCompany
  
  def after_create( pc )
    pc.movie.log_entries << AssocLogEntry.new( :user => self.current_user, :ip_address => self.current_user.ip_address,
                              :new_value => pc.company.id, :old_value => nil, :attribute => Company.to_s.underscore )
  end
  
  def after_destroy( pc )
    pc.movie.log_entries << AssocLogEntry.new( :user => self.current_user, :ip_address => self.current_user.ip_address,
                              :new_value => nil, :old_value => pc.company.id, :attribute => Company.to_s.underscore ) unless current_user.nil?
  end
end
