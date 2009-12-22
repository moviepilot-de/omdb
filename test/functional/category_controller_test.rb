require File.dirname(__FILE__) + '/../test_helper'
require 'category_controller'

# Re-raise errors caught by the controller.
class CategoryController; def rescue_action(e) raise e end; end

class CategoryControllerTest < Test::Unit::TestCase
  include Arts
  include ImageHelper
  include TestOmdbHelper
  
  fixtures :categories, :movies, :name_aliases, 
           :movie_user_categories, :jobs, :users, :contents

  # Test the basic views for a category
  view_test_for :category, :action
  view_test_for :category, :action, :action => :movies, :template => 'movies.rhtml', :common_template => true
  view_test_for :category, :action, :action => :statistics, :template => 'statistics.rhtml', :common_template => true
  view_test_for :category, :action, :action => :tree, :template => 'tree.rhtml', :common_template => true
  
  view_test_for :category, :genre, :action => :movies, :template => 'movies.rhtml', :common_template => true do |instance|
    instance.assert_equal 25, instance.categories(:genre).all_movie_count
    instance.assert_equal 2, instance.assigns(:results).page_count
    instance.assert_no_tag :a, :content => "Cat on a Hot Tin Roof"
  end
  
  view_test_for :category, :genre, :action => :movies, :params => { :page => 2 }, :template => 'movies.rhtml' do |instance|
    instance.assert_tag :a, :content => "Cat on a Hot Tin Roof"
  end

  abstract_test_for :category, :action, :action_abstract

  # test wiki functions
  view_page_tests_for        :category, :action
  write_page_tests_for       :category, :action
  rename_page_tests_for      :category, :action
  page_destruction_tests_for :category, :action
  page_versioning_tests_for  :category, :action
  rss_link_tests_for         :category, :action
  index_page_tests_for       :category, :categories_978

  edit_aliases_test_for :category, :action, "Aktionaer"

  def setup
    @controller = CategoryController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_admin_buttons
    login_as :admin
    get :index, :id => categories(:categories_495).id
    assert categories(:categories_495).root
    assert_response :success
    assert_equal 'index', assigns(:page).page_name
    assert_equal categories(:categories_495), assigns(:category)
    assert_tag :tag => 'h3', :content => 'Administration'
    assert_tag :input, :attributes => { :value => 'merge categories' }
    assert_tag :input, :attributes => { :value => 'create category' }
    assert_tag :input, :attributes => { :value => 'delete category' }
  end
  
  def test_set_parent
    comedy_size = categories(:comedy).children.size
    action_size = categories(:action).children.size

    xhr :post, :update_facts, :id => categories(:slapstick).id, :parent => categories(:action).id, :alias => { :name => "Something" }
    assert_success

    assert_equal (comedy_size - 1), categories(:comedy).children.size
    assert_equal (action_size + 1), categories(:action).children.size
    assert categories(:action).children.include?( categories(:slapstick) )
  end
  
  def test_set_alias
    title = "Brand New Name"
    xhr :post, :update_facts, :id => categories(:slapstick).id, :alias => { :name => title }
    
    assert_response :success
    assert_equal title, categories(:slapstick).name
  end
  
  def test_set_assignable_unallowed
    xhr :post, :update_facts, :id => categories(:slapstick).id, :category => { :assignable => 'false' }
    
    assert_response :success
    assert categories(:slapstick).reload.assignable
  end
  
  def test_set_assignable
    login_as :admin
    xhr :post, :update_facts, :id => categories(:slapstick).id, :category => { :assignable => 'false' }
    
    assert_response :success
    assert !categories(:slapstick).reload.assignable    
  end
  
  def test_new_without_login
    xhr :get, :new, :id => categories(:slapstick).id
    assert_response :success
    assert_equal "window.location.href = \"/account/login\";", @response.body
  end
  
  def test_new_with_login
    login_as :admin
    xhr :get, :new, :id => categories(:slapstick).id
    assert_response :success
  end
  
  def test_create_without_login
    xhr :post, :create
    assert_equal "window.location.href = \"/account/login\";", @response.body
  end
  
  def test_create
    children = categories(:slapstick).children.size
    title = "Brand New Category"
    login_as :admin
    xhr :post, :create, :parent => categories(:slapstick).id, :alias => { :name => title }
    assert_response :success
    
    assert_equal (children + 1), categories(:slapstick).reload.children.size
    assert categories(:slapstick).children.collect{ |c| c.aliases.collect{ |a| a.name } }.flatten.include?( title )
  end

#  def test_add_user_vote_anonymous
#    post :add_user_vote, 
#         :category => categories(:action).id,
#         :movie => movies(:star_wars).id
#    assert_success
#    
#    cat = Category.find(categories(:action).id)
#    assert_equal 0, cat.movie_user_categories.size
#    assert_not_nil flash[:error]
#  end
#  
#  def test_add_user_vote_real_user
#    post :add_user_vote,
#         { :category => categories(:action).id,
#           :movie => movies(:star_wars).id },
#         { :auth_user_id => User.admin.id }
#    assert_success
#
#    cat = Category.find(categories(:action).id)
#    assert_equal 1, cat.movie_user_categories.size
#    assert_equal movies(:star_wars), cat.movie_user_categories.first.movie
#    assert_equal User.admin, cat.movie_user_categories.first.user
#  end
#  
#  def test_add_user_with_second_vote
#    MovieUserCategory.create(:category => categories(:action), :movie => movies(:star_wars), :user => User.admin).save!
#    post :add_user_vote,
#         { :category => categories(:action).id,
#           :movie => movies(:star_wars).id },
#         { :auth_user_id => User.admin.id }
#    assert_success
#
#    vote = MovieUserCategory.find_by_user_id(User.admin.id)
#    assert vote.is_a?(MovieUserCategory)
#    assert_not_nil flash[:error]
#  end
#  
#  def test_view_wiki_for_category
#    get :wiki, :id => categories(:action).id
#    assert_success
#    assert_template "wiki.rhtml"
#  end
#  
#  

#
#  def test_set_abstract
#    abstract = "My shiny new abstract"
#    post :set_abstract, :id => categories(:action).id, :category  => { :abstract => abstract }
#    assert_success
#    assert_equal(abstract, Category.find(categories(:action).id).abstract( Locale.base_language ).data)
#  end
#  
#  
#  def test_max_depth_on_create
#    name = "Sitcomedy"
#    post :create, :tag => { :name => name }, :parent => categories(:slapstick).id
#    assert_success
#    assert_nil flash[:error]
#    
#    sitcom = NameAlias.find_by_name(name).category
#    assert_not_nil sitcom
#    assert_not_nil sitcom.parent
#    assert_equal 1, sitcom.aliases.size
#    # should be Genre > Comedy > Slapstick > Sitcomedy
#    assert_equal 3, sitcom.ancestors.size
#    
#    
#    name = "Comsit"
#    post :create, :tag => { :name => name }, :parent => sitcom.id
#    assert_success
#    assert_not_nil flash[:error]
#    # a depth of more than 3 should be disallowed, "Sitcom" is the third decendant in the tree, so it shouldn't have any children
#    assert_equal 0, sitcom.children.size
#  end
#  
#  def test_max_depth_on_set_parent
#    post :set_parent, :id => categories(:sitcom).id, :category => categories(:slapstick).id
#    assert_success
#    categories(:sitcom).reload
#    assert_nil flash[:error]
#    assert_equal categories(:sitcom).parent, categories(:slapstick)
#    
#    post :set_parent, :id => categories(:comsit).id, :category => categories(:sitcom).id
#    assert_success
#    assert_not_nil flash[:error]
#    assert_equal 0, categories(:comsit).children.size
#  end
#
#  def test_info
#    xhr :get, :info, :id => categories(:action).id
#    assert_success
#    assert @response.body.include?(categories(:action).local_name(Language.find_by_iso_639_1("en")))
#  end
#  
#  def test_popularity
#    get :overview, :id => categories(:sitcom).id
#    
#    assert_not_nil session[:popularities][Category]
#    popularity = Popularity.find_by_for_type_and_for_id("Category", categories(:sitcom).id)
#    assert_not_nil popularity
#  end
#
#  def test_hide_vote_icon_after_vote
#    xhr :post, :add_user_vote,
#         { :category => categories(:action).id,
#           :movie => movies(:star_wars).id },
#         { :auth_user_id => User.admin.id }
#    assert_success
#    assert_nil @response.body.match(/\/images\/icons\/plus\.gif/)
#    assert_not_nil @response.body.match(/\/images\/icons\/delete\.png/)
#  end


end
