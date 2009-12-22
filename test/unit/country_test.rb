require File.dirname(__FILE__) + '/../test_helper'

class CountryTest < Test::Unit::TestCase
  fixtures :categories, :jobs, :casts, :people, :movies, :globalize_countries, :movie_countries, :name_aliases

  def setup
  end

  def test_chronological_movies
    usa = Country.find 223
    assert usa.chronological_movies.any?
    m = usa.chronological_movies.first
    assert Movie === m, m.inspect
  end

end

