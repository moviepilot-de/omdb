require File.dirname(__FILE__) + '/../test_helper'

class IndexerTest < Test::Unit::TestCase
  fixtures :movies, :categories, :jobs

  def setup
    @movie = movies(:king_kong)
  end
  
  def teardown
    Searcher.close!
  end

  def test_index_key
    assert_equal "movie_#{@movie.id}", Indexer.index_key(@movie)
    assert_equal "movie_12", Indexer.index_key(:class => Movie, :id => 12)
    assert_equal "movie_12", Indexer.index_key(:class => 'Movie', :id => 12)
  end

  def test_index_and_destroy
    Indexer.index_object :type => @movie.class.name, :id => @movie.id
    # finds king kong and king of comedy
    assert_equal 2, Searcher.search('king kong').size
    Indexer.delete_object :type => @movie.class.name, :id => @movie.id
    assert_equal 1, Searcher.search('king kong').size
  end
end
