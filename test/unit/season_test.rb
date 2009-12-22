require File.dirname(__FILE__) + '/../test_helper'

class SeasonTest < Test::Unit::TestCase
  fixtures :categories, :jobs, :casts, :people, :movies
  set_fixture_class(:globalize_languages => "Language")

  def setup
  end

  def test_season_number
    assert_equal 1, movies(:star_trek_tng_season_one).season_number
  end
end
