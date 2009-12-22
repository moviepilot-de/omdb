module TrackBackable
  def self.included(base) # :nodoc:
    base.send( :has_many, :track_backs, :as => :tracked_object, :order => 'created_at DESC, id DESC' )
    base.extend ClassMethods
  end
  
  # Trackback paging accessor
  def trackbacks( page = 1, language = Locale.base_language )
    track_backs.find( :all, :page => { :size => 5, :current => page }, :conditions => [ 'language_id = ? and is_spam = 0', language.id ] )
  end
  
  module ClassMethods
  end
end