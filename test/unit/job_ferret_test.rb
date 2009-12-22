require File.dirname(__FILE__) + '/../test_helper'

class JobFerretTest < Test::Unit::TestCase
  fixtures :jobs, :movies, :people

  def teardown
    Searcher.close!
  end

  def test_search
    results = Job.search( 'director' )
    assert results.collect{|j| j.to_o}.include?( jobs(:director) )
  end

  def test_livesearch
    jobs = Job.search_by_prefix( 'dire', Locale.base_language )
    assert jobs.collect{|j| j.to_o}.include?( jobs(:director) )
    assert jobs.collect{|j| j.to_o}.include?( jobs(:director_of_photography) )
  end
  
  def test_livesearch_multiple_terms
    jobs = Job.search_by_prefix( 'dire pho', Locale.base_language )
    assert jobs.collect{|j| j.to_o}.include?( jobs(:director_of_photography) )
    assert !jobs.collect{|j| j.to_o}.include?( jobs(:director) )
  end

end
