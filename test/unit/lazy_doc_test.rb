require File.dirname(__FILE__) + '/../test_helper'

class LazyDocTest < Test::Unit::TestCase
  fixtures :categories, :name_aliases

  def test_find_category
    results = Searcher.search_categories 'action'
    assert results[0].is_a?( Ferret::Index::LazyDoc )
    assert results[0].to_o.is_a?( Category )    
  end
  
  def test_category_name_fallback
    results = Searcher.search_categories 'act'
    assert results[0].is_a?( Ferret::Index::LazyDoc )
    assert_equal categories(:action).name, results[0].name
    assert results[0].movies.any? # and fallback to AR-relations
  end

end
