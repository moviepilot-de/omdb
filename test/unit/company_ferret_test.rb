require File.dirname(__FILE__) + '/../test_helper'

class CompanyFerretTest < Test::Unit::TestCase
  fixtures :movies, :categories, :jobs, :casts, :people, :name_aliases, :movie_user_categories, :companies

  def teardown
    Searcher.close!
  end

  def test_indexing
    company = Company.find(companies(:paramount).id)
    company.name = company.name.reverse
    company.save
    results = Searcher.search_encyclopedia( company.name, Locale.base_language )
    assert results.collect{|c| c.to_o}.include?( Company.find( companies(:paramount).id ) )
  end

  def test_company_search
    results = Company.search( 'films', Locale.base_language )
    assert_equal 5, results.size
    assert results.collect{|c| c.to_o}.include?( companies(:wingnut) )
  end

  def test_livesearch
    results = Company.search_by_prefix( 'un' )
    assert 2, results.size
    assert results.collect{|c| c.to_o}.include?( companies(:universal) ) 
  end

end
