require File.dirname(__FILE__) + '/../test_helper'

class MovieUserCategoryTest < Test::Unit::TestCase
  fixtures :users, :movies, :categories, :movie_user_categories, :name_aliases, :jobs
  
  def setup
  end
  
  def test_assign_incomplete
    vote = MovieUserCategory.new( :movie => movies(:king_kong), :category => categories(:action) )
    assert !vote.save
    vote = MovieUserCategory.new( :movie => movies(:king_kong), :user => users(:franz) )
    assert !vote.save
    vote = MovieUserCategory.new( :category => categories(:action), :user => users(:franz) )
    assert !vote.save
  end
  
  def test_assign_unassignable_category
    vote = MovieUserCategory.new( :movie => movies(:king_kong), :category => categories(:europe), :user => users(:quentin) )
    assert !vote.save
  end
  
  def test_assign_twice
    vote = MovieUserCategory.new( :movie => movies(:king_kong), :category => categories(:action), :user => users(:franz) )
    assert vote.save
    vote = MovieUserCategory.new( :movie => movies(:king_kong), :category => categories(:action), :user => users(:franz) )
    assert !vote.save    
  end

end
