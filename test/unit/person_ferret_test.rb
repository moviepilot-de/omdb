require File.dirname(__FILE__) + '/../test_helper'

class PersonFerretTest < Test::Unit::TestCase
  fixtures :people, :movies, :casts, :jobs, :categories
 
  def teardown
    Searcher.close!
  end

  def test_search
    results = Searcher.search 'Peter'
    assert results.collect{|o| o.to_o}.include?( people(:peter_jackson) )
    assert results.collect{|o| o.to_o}.include?( movies(:king_kong) )
  end

  def test_umlaut_nivellierung
    results = Searcher.search 'ümläut'
    assert results.collect{|o| o.to_o}.include?(people(:umlaute))
    results = Searcher.search 'umlaut'
    assert results.collect{|o| o.to_o}.include?(people(:umlaute))
  end
  
  def test_remove_after_destroy
    results = Searcher.search_people_by_prefix('chr ka')
    assert results.collect{|o| o.to_o}.include?(people(:christine_kaufmann))
    people(:christine_kaufmann).destroy
    results = Searcher.search_people_by_prefix('chr ka')
    assert !results.collect{|o| o.to_o}.include?(people(:christine_kaufmann))    
  end

  # Search people by prefix .. should include Jack Black and Jan Blenkin
  def test_livesearch
    people = Person.search_by_prefix( 'ja bl', Locale.base_language )
    assert_equal 2, people.size
    assert people(:jack_black), people.first.to_o
  end

end
