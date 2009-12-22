require File.dirname(__FILE__) + '/../test_helper'

class MovieUserTagTest < Test::Unit::TestCase
  fixtures :movie_user_tags, :movies, :users

  def test_add_movie
    user = users(:quentin)
    assert_equal 1, user.movie_user_tags.size
    user.movie_user_tags.create( :movie => movies(:king_kong), :tag => 'default' )
    assert_equal 2, user.movie_user_tags.size
    assert_equal movies(:king_kong).id, user.movie_user_tags.first.movie.id
  end
end
