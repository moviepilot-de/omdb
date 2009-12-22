require File.dirname(__FILE__) + '/../test_helper'

class MovieFerretTest < Test::Unit::TestCase
  fixtures :movies, :categories, :jobs, :casts, :people, :name_aliases, :movie_user_categories
  
  def teardown
    Searcher.close!
  end

  # Search for valid parents of a Season (should be just Series)
  def test_find_parent_for_season
    movie = Season.new
    movie.name = "Season One"
    parents = Searcher.search_good_parents movie, 'star', 'en'
    assert_equal( 1, parents.length )
    assert parents.collect{|m| m.to_o}.include?( movies(:star_trek_tng) )
  end

  # Search for valid parents of a Episode (should be just Seasons)
  def test_find_parent_for_episode
    movie = Episode.new
    movie.name = "Encounter at Farpoint"
    parents = Searcher.search_good_parents movie, 'star', 'en'
    assert_equal( 1, parents.size )
    assert parents.collect.include?( movies(:star_trek_tng_season_one) )
  end
  
  def test_find_good_children
    movie = movies(:batman_series)
    results = Searcher.search_good_children movie, 'willy', Locale.base_language.code
    assert_equal 1, results.size
    assert_equal results.first.id, movies(:willy_wonka).id
  end

  # Simple search
  def test_movie_search
    results = Searcher.search_movies( 'King', Locale.base_language.code )
    assert_equal( 2, results.size )
  end

  # Test livesearch feature
  def test_movie_livesearch
    results = Searcher.search_movies_by_prefix( 'Kin', Locale.base_language.code )
    assert_equal( 2, results.length )
  end

  # Test ordering by popularity
  def test_movie_order
    results = Searcher.search_movies( 'King', Locale.base_language.code )
    assert_equal( movies(:king_of_comedy), results.to_a[0].to_o )
    assert_equal( movies(:king_kong), results.to_a[1].to_o )
    assert_equal 2, results.size
  end

end
