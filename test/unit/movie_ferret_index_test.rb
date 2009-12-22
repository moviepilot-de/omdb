require File.dirname(__FILE__) + '/../test_helper'

class MovieFerretIndexTest < Test::Unit::TestCase
  fixtures :movies, :categories, :jobs, :casts, :people, :name_aliases, :movie_user_categories

  def teardown
    Searcher.close!
  end

  # Find a Movie by searching for its name
  def test_indexing
    movie = Movie.find(movies(:king_kong).id)
    movie.name = movie.name.reverse
    movie.save
    @results = results = Searcher.search( movie.name )
    assert_equal( 1, results.size )
  end

  # Searching for an actor should also return the movie he's been playing in
  def test_searching_movie_cast
    movie = Movie.find(movies(:king_kong).id)
    movie.name = movie.name
    movie.save
    results = Searcher.search( people(:naomi_watts).name )
    assert results.collect{|c| c.to_o}.include?( movie )
  end

  # Search for Category "Adventure"
  def test_searching_movie_category
    movie = Movie.find(movies(:king_kong).id)
    movie.name = movie.name
    movie.save
    results = Searcher.search( categories(:adventure).name )
    assert results.collect{|c| c.to_o}.include?( movie )
  end

  # Search for Plot Keyword "Jungle"
  def test_searching_movie_keyword
    movie = Movie.find(movies(:king_kong).id)
    movie.name = movie.name
    movie.save
    results = Searcher.search( categories(:jungle).name )
    assert results.collect{|c| c.to_o}.include?( movie )
  end

  # Search for movie aliases
  def test_searching_movie_alias
    movie = Movie.find(movies(:king_kong).id)
    movie.aliases << NameAlias.new( :language => Locale.base_language, :name => "brand new alias" )
    movie.save
    results = Searcher.search( "brand new alias" )
    assert results.collect{|c| c.to_o}.include?( movie )
  end

end
