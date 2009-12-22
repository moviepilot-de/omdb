require File.dirname(__FILE__) + '/../test_helper'
require 'cast_controller'

# Re-raise errors caught by the controller.
class CastController; def rescue_action(e) raise e end; end

class CastControllerTest < Test::Unit::TestCase
  include TestOmdbHelper

  fixtures :movies, :characters, :casts, :people, :movies, :jobs, :categories

  view_test_for :cast, :the_journalist, :action => :create_character, :template => 'create_character.rhtml', :xhr => true
  
  def setup
    @controller = CastController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_view_new
    xhr :get, :new, :movie => movies(:ghost).id
    assert_success
    assert_template 'new.rhtml'
  end
  
  def test_view_new_cast
    xhr :get, :new_cast, :movie => movies(:ghost).id
    assert_success
    assert_template 'new_cast.rhtml'
  end
  
  def test_create_cast
    character_name = "Test Character"
    xhr :post, :create_cast, :movie => movies(:ghost).id, :cast => { :person => people(:china_doll).id.to_s, :comment => character_name }
    assert_success
    
    assert people(:china_doll).movies.include?( movies(:ghost) )
    assert_equal character_name, movies(:ghost).actors.delete_if{ |c| c.person.id != people(:china_doll).id }.first.comment
  end
  
  def test_create_crew
    xhr :post, :create, :movie => movies(:ghost).id, :crew => { :person => people(:peter_jackson).id.to_s, :job => jobs(:director_of_photography).id.to_s }
    assert_success

    assert movies(:ghost).directors_of_photography.collect{ |c| c.person }.include?( people(:peter_jackson) )
  end

  def test_assign_cast_to_character
    xhr :post, :assign_character, :id => casts(:the_journalist).id, :character => characters(:dracula).id
    assert_success
    
    cast = Cast.find(casts(:the_journalist).id)
    assert_equal characters(:dracula).id, cast.character.id
  end

  def test_update_character_no_data
    cast = casts(:casts_148)
    xhr :post, :update_character, :id => cast.id
    assert_success
    assert_equal cast.comment, Cast.find(cast.id).comment
  end

  def test_update_character_comment
    cast = casts(:casts_148)
    xhr :post, :update_character, :id => cast.id, :cast => { :comment => 'new comment' }
    assert_success
    assert_equal 'new comment', Cast.find(cast.id).comment
  end

  def test_create_alias
    cast = casts(:casts_148)
    xhr :post, :set_alias, :id => cast.id, :alias => { :name => 'test' }
    assert_success
    assert_equal 1, Cast.find(cast.id).aliases.length
  end

  def test_create_new_character
    cast = casts(:franz)
    xhr :post, :create_new_character, :id => cast.id
    assert_response :success
    assert_not_nil cast.reload.character
  end

  def test_freeze_without_login
    cast = casts(:prostitute_2)
    assert !cast.frozen?
    
    xhr :get, :freeze_attribute, :id => casts(:prostitute_2).id
    # :TODO: currently a javascript redirect - we need to think of a better way
    assert_response :success
    
    assert !cast.reload.frozen?
  end

  def test_freeze
    login_as :admin
    cast = Cast.find(casts(:drunken_man).id)
    assert !cast.frozen?
    
    xhr :get, :freeze_attribute, :id => casts(:drunken_man).id
    assert_success
    
    assert cast.reload.frozen?
  end
  
  def test_unfreeze
    cast = casts(:drunken_man)
    cast.set_frozen
    cast.save!

    xhr :get, :unfreeze_attribute, :id => casts(:drunken_man).id
    
    cast = Cast.find(casts(:drunken_man).id)
    assert !cast.frozen?
  end
end
