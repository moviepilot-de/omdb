class MovieUserTag < ActiveRecord::Base
  belongs_to :movie
  belongs_to :user
  
  depending_objects [ :movie ]
  
  validates_presence_of :movie, :user, :tag
  validates_uniqueness_of :tag, :scope => [ :movie_id, :user_id ]
end
