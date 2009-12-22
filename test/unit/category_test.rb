require File.dirname(__FILE__) + '/../test_helper'

class CategoryTest < Test::Unit::TestCase
  fixtures :categories, :name_aliases, :movies, :users, :jobs, :casts, :people, :movie_user_categories

  def setup
  end
  
  def test_base_name
    assert_equal 'genre', Category.find(1).base_name
  end
  
  def test_merge_categories
    assert 1, categories(:macguffin).movies.size
    assert 1, categories(:music_band).movies.size
    name = categories(:macguffin).name
    
    categories(:music_band).merge( [ categories(:macguffin) ] )
    assert 2, categories(:music_band).reload.movies.size
    assert_raise ActiveRecord::RecordNotFound do
      Category.find( categories(:macguffin).id )
    end
    
    assert categories(:music_band).name_aliases.collect{|a| a.name}.include?( name )
  end
  
  
  # should result in english version although german is set up as language
  def test_local_name_with_different_language
    cat = Category.create
    cat.aliases.create(:name => "Science-Fiction", :language => Language.find_by_iso_639_1("en"))
    language = Language.find_by_iso_639_1("de")
    assert_equal "Science-Fiction", cat.local_name(language)
  end
  
  def test_local_name_with_same_language
    cat = Category.create
    cat.aliases.create(:name => "Science-Fiction", :language => Language.find_by_iso_639_1("en"))
    assert_equal "Science-Fiction", cat.local_name(nil)
  end
  
  def test_flattened_name
    cat = Category.create(:parent => categories(:action))
    cat.aliases.create(:name => "Science-Fiction", :language => Language.find_by_iso_639_1("en"))
    
    assert_equal "Action > Science-Fiction", cat.flattened_name(nil)
    assert_equal "Genre > Action > Science-Fiction", cat.full_flattened_name(nil)
  end
  
  def test_count_for_movie
    categories(:action).movie_user_categories.create(:user => User.anonymous, :movie => movies(:star_wars))
    
    count = categories(:action).count_for_movie(movies(:star_wars))
    assert_equal 1, count
  end
  
  def test_categories_for_movie
    MovieUserCategory.delete_all
    MovieUserCategory.create(:movie => movies(:star_wars),
                             :user => users(:admin),
                             :category => categories(:action)).save!
    MovieUserCategory.create(:movie => movies(:star_wars),
                             :user => User.anonymous,
                             :category => categories(:action)).save!
    MovieUserCategory.create(:movie => movies(:star_wars),
                             :user => users(:admin),
                             :category => categories(:comedy)).save!
    categories = Category.categories_for_movie(movies(:star_wars))
    assert_not_nil categories
    assert_equal 2, categories.size
    assert_equal categories(:action).id, categories.first.id
  end

  def test_top_movies
    MovieUserCategory.delete_all
    create_votes categories(:action), movies(:king_kong), 1
    create_votes categories(:action), movies(:star_wars), 1
    create_votes categories(:action), movies(:batman), 1
    
    assert_equal 3, categories(:action).highest_rated_movies.size
    assert_equal movies(:star_wars).name, categories(:action).highest_rated_movies.first.name
    assert_equal movies(:batman).name, categories(:action).highest_rated_movies.last.name
  end
  
  private
  
  def create_votes(category, movie, count)
    count.times do |i|
      MovieUserCategory.create(:category => category, :movie => movie, :user => users(:admin)).save!
    end
  end
end
