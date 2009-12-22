require File.dirname(__FILE__) + '/../test_helper'

class EpisodeTest < Test::Unit::TestCase
  fixtures :movies, :categories, :jobs, :casts, :people

  def setup
  end

  def test_page_uses_correct_related_object_class
    movie = Episode.new( :name => "Episode One" )
    movie.parent = Movie.find( movies(:star_trek_tng_season_one).id )
    assert movie.save
    assert_equal 'Movie', movie.send(:toplevel_class).name
    page = movie.page 'index', Locale.base_language
    assert_equal 'Movie', page.related_object_type
  end

  # Test cast inheritance
  def test_episode_directors
    movie = Episode.new( :name => "Episode One" )
    movie.parent = Movie.find( movies(:star_trek_tng_season_one).id )
    directors = movie.directors
    assert_equal( 1, movie.directors.size )
  end

  # Test cast inheritance
  def test_episode_directors
    movie = Episode.new( :name => "Episode One" )
    movie.parent = Movie.find( movies(:star_trek_tng_season_one).id )
    movie.parent.inherit_cast = false
    directors = movie.directors
    assert_equal( 0, movie.directors.size )
  end

end
