require File.dirname(__FILE__) + '/../test_helper'

class MovieUserCategoryFerretTest < Test::Unit::TestCase
  fixtures :users, :movies, :categories, :movie_user_categories, :name_aliases, :jobs

  def setup
    # Indexer.reindex
    SearchObserver.instance
  end
  
  def teardown
    Searcher.close!
  end
  
  def test_search_for_unassignable_category
    results = Searcher.search_categories('Europe')
    assert results.collect{|c| c.to_o}.include?( categories(:europe) )
    results = Searcher.search_categories_by_prefix('euro')
    assert !results.collect{|c| c.to_o}.include?( categories(:europe) )
  end
  
  def test_search_category
    results = Category.search_localized( 'Horror', Locale.base_language )
    assert results.collect{|c| c.to_o}.include?( categories(:horror) )
    new_category = MovieUserCategory.create! :user => users(:anonymous), 
                                             :movie => movies(:big_lebowski), 
                                             :category => categories(:horror)
    assert_equal 2, new_category.dependent_objects.size
    results = Searcher.search('Horror', Locale.base_language.code)
    assert results.collect{|c| c.to_o}.include?( movies(:big_lebowski) ), results.inspect

    added_category = MovieUserCategory.find(:all, :conditions => [ "movie_id = ? and user_id = ? and category_id = ?", movies(:big_lebowski).id, users(:anonymous).id, categories(:horror).id ])
    assert_equal 1, added_category.size
    added_category[0].destroy
    results = Searcher.search('Horror', Locale.base_language.code)
    assert !results.collect{|c| c.to_o}.include?( movies(:big_lebowski) )
  end

end
