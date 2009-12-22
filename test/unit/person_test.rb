require File.dirname(__FILE__) + '/../test_helper'

class PersonTest < Test::Unit::TestCase
  fixtures :movies, :casts, :jobs, :people

  def setup
  end

  # Should have one last_movie, King Kong
  def test_person_movies
    peter = Person.find( people(:peter_jackson).id )
    assert_equal false, peter.last_movies.empty?
    assert_equal true, peter.last_movies.include?( movies(:king_kong) )
  end
  
  def test_merge
    p1 = people(:china_doll)
    p2 = people(:willy_harlander)
    
    assert_equal 1, p1.movies.size
    assert_equal 1, p2.movies.size
    
    p1.merge( [p2] )
    assert_equal 2, p1.reload.movies.size
    assert_raise ActiveRecord::RecordNotFound do
      Person.find( people(:willy_harlander).id )
    end    
  end

  # Peter is not planning any movie right now
  def test_person_no_upcoming_movies
    peter = Person.find( people(:peter_jackson).id )
    assert_equal true, peter.upcoming_movies.empty?
  end

  # But Elijah is..
  def test_person_upcoming_movies
    elijah = Person.find( people(:elijah_wood).id )
    assert_equal 2, elijah.movies.size
    assert_equal 1, elijah.upcoming_movies.size
    assert_equal 1, elijah.last_movies.size
    assert_equal true, elijah.upcoming_movies.include?( movies(:cat_on_a_hot_tin_roof) )
  end

  # Should consist of Director, Producer and Author
  def test_person_jobs
    peter = Person.find( people(:peter_jackson).id )
    assert_equal 3, peter.jobs.size
    assert_equal true, peter.jobs.include?( Job.director )
    assert_equal true, peter.jobs.include?( Job.producer )
    # Authors have a special treatment, we should consider fixing that,
    # but right now it's working fine.
    assert_equal true, peter.jobs.include?( Job.author.first )
  end

  # Should find Helen Rose .. 
  def test_orphans
    orphans = Person.find_orphans
    assert_equal 4, orphans.size
    assert_equal true, orphans.include?( Person.find( people(:helen_rose).id ) )
  end
end
