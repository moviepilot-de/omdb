require File.dirname(__FILE__) + '/../test_helper'

class MovieTest < Test::Unit::TestCase
  fixtures :categories, :jobs, :casts, :people, :movies, :movie_user_categories

  def setup
  end

  def test_destroy
    movie = Movie.find( movies(:king_kong).id )
    movie.destroy
    assert_raises ActiveRecord::RecordNotFound do
      Movie.find movie.id 
    end
  end

  def test_page
    m = movies(:encounter_at_farpoint)
    p = m.wiki_index globalize_languages(:german)
    p1 = m.wiki_index globalize_languages(:german)
    assert_equal p, p1
  end

  def test_categories
    cats = movies(:king_kong).categories
    assert cats.any?
  end
  def test_category_ids
    ids = movies(:king_kong).category_ids
    assert Fixnum === ids.first
  end
  
  def test_configuration_movie
    assert Movie.has_votes?
  end
  
  def test_configuration_movieseries
    assert !MovieSeries.has_votes?
  end

  def test_name
    m = Movie.new
    m.name = "The Godfather"
    assert_equal("The Godfather", m.name)
  end

  def test_movie_cast
    movie = Movie.find( movies(:king_kong).id )
    assert !movie.casts.empty?
  end

  def test_movie_actors
    movie = Movie.find( movies(:king_kong).id )
    assert !false, movie.actors.empty?
  end

  # Fin all Actors (casts of class actors, that is)
  def test_movie_actor
    movie = Movie.find( movies(:king_kong).id )
    naomi = Person.find( people(:naomi_watts).id )
    assert movie.actors.collect{ |c| c.person }.include?( naomi )
  end

  # find all Authors (Author, Screenplay and Story)
  def test_movie_authors
    movie   = Movie.find( movies(:the_39_steps).id )
    authors = movie.authors.collect{ |c| c.person }

    assert authors.include?( people(:john_buchan) )
    assert authors.include?( people(:charles_bennett) )
    assert authors.include?( people(:alma_reville) )
  end

  # find all Directors of a Movie
  def test_movie_director
    movie     = movies(:king_kong)
    directors = movie.directors.collect{ |c| c.person }
    assert directors.include?( people(:peter_jackson) )
  end
  
  # find all Directors of a MovieSeries (aka all directors of all children)
  def test_movie_directors_of_series
    directors = movies(:batman_series).directors.collect{ |c| c.person }
    assert directors.include?( people(:tim_burton) )    
  end

  # Try to set an invalid parent for a movie
  def test_movie_invalid_parent
    movie  = Movie.find( movies(:king_kong).id )
    parent = Movie.find( movies(:lili_marleen).id )
    movie.parent = parent
    assert !movie.valid?
#    assert !movie.save
  end
  
  # Try to set self as a parent
  def test_movie_invalid_parent_self
    movie = movies(:batman_series)
    movie.parent = movies(:batman_series)
    assert !movie.valid?
  end

  # Try to set a valid parent for a movie
  def test_movie_valid_parent
    movie  = Movie.find( movies(:king_kong).id )
    parent = Movie.find( movies(:batman_series).id )
    movie.parent = parent
    assert movie.save
    assert_equal( 2, parent.children.size )
  end


end
