require File.dirname(__FILE__) + '/../test_helper'

class MovieFilterTest < Test::Unit::TestCase
  fixtures :movies, :categories, :jobs, :casts, :people, :companies,
           :globalize_countries, :movie_countries, :movie_languages, :production_companies

  def setup
    Indexer.reindex
    @movie_filter = MovieFilter.new
  end
  
  def teardown
    Searcher.close!
  end

  def test_filter_by_categories
    movies = Searcher.search_filtered_movies("*", @movie_filter)
    assert_equal 25, movies.size
    @movie_filter.add_country_id(Country.find_by_code('US').id)
    movies = Searcher.search_filtered_movies("*", @movie_filter)
    # ["King of Comedy", "Ghost", "Cat on a Hot Tin Roof", "Batman", "King Kong"]
    assert_equal 5, movies.size
    # should eliminate "King of Comedy", "Ghost", "Cat on a Hot Tin Roof" and 
    @movie_filter.add_category_id(categories( :action ).id)
    movies = Searcher.search_filtered_movies("*", @movie_filter)
    assert_equal 1, movies.size
    assert_equal movies( :batman ), movies.first.to_o
  end

  def test_filter_by_language
    @movie_filter.add_country_id(Country.find_by_code('US').id)
    # ["King of Comedy", "Ghost", "Cat on a Hot Tin Roof", "Batman", "King Kong"]
    movies = Searcher.search_filtered_movies("*", @movie_filter)
    # should still be 5
    assert_equal 5, movies.size
    # now in "King of Comedy", "Ghost" they speak german .. (at least in this test)
    @movie_filter.add_language(Language.find_by_english_name('German'))
    movies = Searcher.search_filtered_movies("*", @movie_filter)
    assert_equal 2, movies.size
  end

  def test_filter_by_person
    movies = Movie.find_all
    assert_equal 26, movies.size
    # We place Naomi in King of Comedy and of course King Kong
    @movie_filter.add_person_id(people( :naomi_watts ).id)
    movies = Searcher.search_filtered_movies("*", @movie_filter)
    assert_equal 2, movies.size
  end

  def test_filter_by_company
    # Should find "Baisers voles", "Domicile Conjugal" and "L'Amour en Fuite"
    @movie_filter.add_company(companies( :films_carrosse ))
    movies = Searcher.search_filtered_movies("*", @movie_filter)
    assert_equal 3, movies.size
    # should eliminate Domicile Conjugal
    @movie_filter.add_category(categories( :marriage ))
    movies = Searcher.search_filtered_movies("*", @movie_filter)
    assert_equal 2, movies.size
  end

  def test_filter_by_plot_keyword
    # King Kong and Ghost were filmed in New York
    @movie_filter.add_keyword( categories(:new_york) )
    movies = Searcher.search_filtered_movies("*", @movie_filter)
    assert_equal 2, movies.size
    assert_equal true, movies.include?( movies( :ghost ) )
  end
end
