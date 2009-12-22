require File.dirname(__FILE__) + '/../test_helper'

class CountryFerretTest < Test::Unit::TestCase
  fixtures :movies, :movie_countries, :name_aliases, :globalize_countries

  def teardown
    Searcher.close!
  end

  def test_indexing_alias
    country = Country.find( 123 )
    a = NameAlias.new( :related_object => country, :language => Locale.base_language )
    a.name = "New Name for this Country"
    a.save
    results = Country.search_by_prefix( "name", Locale.base_language )
    assert results.collect{|c| c.to_o}.include?( country )
  end
  
  def test_search_country
    countries = Country.search_by_prefix( 'unit', Locale.base_language )
    assert countries.collect{|c| c.to_o}.include?( Country.find(2) )
    assert countries.collect{|c| c.to_o}.include?( Country.find(75) )
  end

end

