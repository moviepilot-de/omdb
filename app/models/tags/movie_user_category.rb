# The relation table between categories, users and movies
class MovieUserCategory < ActiveRecord::Base
  belongs_to :user
  belongs_to :category
  belongs_to :movie

  # We need all relations to be a real vote.
  validates_presence_of :user, :category, :movie
    
  # Any user (including Anonymous) might only vote once for a movie-category-relation
  validates_uniqueness_of :user_id, :scope => [ :movie_id, :category_id ]

  # Make sure, the category is assignable (see Category). Only accept votes for 
  # assignable categories. If 
  def validate_on_create 
    errors.add("Unassignable Category selected") if !self.category.assignable unless (self.value == -1) unless self.category.nil?
  end
  
  # no need to reindex, if this is "just another" vote. So we only
  # need to reindex, if this is the first or the last vote.
  def skip_indexing
    return MovieUserCategory.find_votes_for_movie(self.movie, self.category) >= 2
  end

  def dependent_objects
    if MovieUserCategory.find_votes_for_movie(movie, category) < 2
      return { 'Movie' => [ self.movie_id], 'Category' => [ self.category_id ] }
    else
      return {}
    end
  end
  
  # not adding user as a related object since the indexer can't handle them, assinging them true or false
  # for correct deletion an indexer delete call should not delete the movie key
  # def related_object
  #   return [ self.movie, self.category ]
  # end

  # Find all votes from one user for a specific movie-category relation.
  def self.find_user_vote_for_movie_and_category( user, movie, category )
    if category.nil?
      MovieUserCategory.find(:first, :conditions => [ "movie_id = ? and user_id = ?", movie.id, user.id ])
    else
      MovieUserCategory.find(:first, :conditions => [ "movie_id = ? and user_id = ? and category_id = ?", movie.id, user.id, category.id ])
    end
  end  
  
  def self.register_user_vote_for_movie_category( user, movie, category, value )
    vote = MovieUserCategory.find_user_vote_for_movie_and_category( user, movie, category )
    if vote.nil?
      # This is the first vote for this user in this movie-category relation
      movie_user_tag = MovieUserCategory.new(:user => user, :category => category, :movie => movie, :value => value )
      movie_user_tag.save!
    else
      # Same value voted twice? Ignore this vote ..
      return if vote.value == value
      # The user has already voted for this movie-category relation, therefore
      # this must be the "counter-vote", we can safely delete all votes of this
      # user for this movie-category relation.
      self.delete_user_votes_for_movie_category user, movie, category
    end
    self.update_movie_category( movie, category )
  end

  # Update the total count of a movie-category relation. If the sum of all positive and
  # negative votes is less then one, all votes can be deleted, so voting can start again :-)
  def self.update_movie_category( movie, category )
    if category.count_for_movie( movie ) < 1
      category.destroy_all_votes_for_movie( movie )
    end
  end
    
  # Deletes all votes of a one user for a specific movie-category relation. There should never
  # be more than one vote in the db, but we make sure all votes gets deleted.
  def self.delete_user_votes_for_movie_category( user, movie, category )
    MovieUserCategory.destroy_all( [ "movie_id = ? and user_id = ? and category_id = ?", 
                                     movie.id, user.id, category.id ] )
  end
  
  def self.find_votes_for_movie( movie, category )
    MovieUserCategory.count( :conditions => [ "movie_id = ? and category_id = ?", movie.id, category.id ])
  end
  
  def self.find_user_votes( user )
    MovieUserCategory.find_by_user_id(user.id)
  end
  
end
