require File.dirname(__FILE__) + '/../test_helper'
require 'user_controller'

# Re-raise errors caught by the controller.
class UserController; def rescue_action(e) raise e end; end

class UserControllerTest < Test::Unit::TestCase
  include TestOmdbHelper
  fixtures :contents, :characters, :log_entries, :movie_user_tags, :movies

  def setup
    @controller = UserController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @quentin = users(:quentin)
  end
  
  # test wiki functions
  view_page_tests_for        :user, :quentin, :readonly => true
  write_page_tests_for       :user, :quentin, :readonly => true, :login_as => :quentin
  page_destruction_tests_for :user, :quentin, :readonly => true, :login_as => :quentin
  page_versioning_tests_for  :user, :quentin, :readonly => true
  rss_link_tests_for         :user, :quentin
  index_page_tests_for       :user, :editor
  
  image_test_for             :user, :quentin
  
  view_test_for :user, :quentin, :action => :contribs, :template => 'contribs.rhtml' do |i|
    i.assert_tag 'a', :content => 'Cat on a Hot Tin Roof'
  end
  
  view_test_for :user, :quentin, :action => :movies, :template => 'movies.rhtml', :common_template => true do |i|
    i.assert_tag 'a', :content => 'King Kong'
  end
  
  view_test_for :user, :quentin, :action => :created, :template => 'movies.rhtml', :common_template => true do |i|
    i.assert_tag 'a', :content => 'In China They Eat Dogs'
  end


  # TODO is the implicit creation of index page when anybody visits 
  # this page a good thing ?
  def test_index
    assert_difference Page, :count do
      get :index, :id => users(:aaron).id
    end
    assert_response :success
    assert_no_difference Page, :count do
      get :index, :id => users(:aaron).id
    end
    assert_response :success
    assert assigns(:page)
    assert_equal 'index', assigns(:page).page_name
  end
  
  def test_add_to_my_movies_without_login
    post :add_movie, :id => users(:quentin).permalink, :movie => movies(:lili_marleen).id, :tag => 'default'
    assert_response :redirect
    assert_redirected_to :controller => 'account', :action => 'login'
  end
  
  def test_delete_from_my_movies_without_login
    post :delete_movie, :id => users(:quentin).permalink, :movie => movies(:lili_marleen).id, :tag => 'default'
    assert_response :redirect
    assert_redirected_to :controller => 'account', :action => 'login'    
  end
  
  def test_add_to_my_movies
    login_as :quentin
    assert_equal 1, users(:quentin).movies.size
    post :add_movie, :id => users(:quentin).permalink, :movie => movies(:lili_marleen).id, :tag => 'default'
    assert_response :redirect
    assert_equal 2, users(:quentin).reload.movies.size
  end
  
  def test_delete_from_my_movies
    login_as :quentin
    post :delete_movie, :id => users(:quentin).permalink, :movie => movies(:king_kong).id, :tag => 'default'
    assert_response :redirect
    assert_equal 0, users(:quentin).movies.size
  end

  def test_image_upload
    xhr :post, :new_image, :id => users(:quentin).permalink
    assert_response :success
    assert_equal 'window.location.href = "/account/login";', @response.body
  end
  
  def test_image_upload_wrong_user
    login_as :aaron
    xhr :post, :new_image, :id => users(:quentin).permalink
    assert_equal 'window.location.href = "/account/login";', @response.body
  end
  
  def test_uniquness_of_my_movies
    login_as :quentin
    assert_equal 1, users(:quentin).movies.size
    post :add_movie, :id => users(:quentin).permalink, :movie => movies(:lili_marleen).id, :tag => 'default'
    assert_response :redirect
    assert_equal 2, users(:quentin).reload.movies.size
    post :add_movie, :id => users(:quentin).permalink, :movie => movies(:lili_marleen).id, :tag => 'default'
    assert_response :redirect
    assert_equal 2, users(:quentin).reload.movies.reload.size
  end

  def test_page_anonymous_visit
    p = create_page
    get :page, :page => p.page_name, :id => users(:quentin).id
    assert_response :success
    assert_template 'page.rhtml'
    assert_no_tag :tag => 'a', :content => 'edit article'
    assert_no_tag :tag => 'a', :content => 'create article'
    assert_tag :tag => 'div', :content => p.data
  end

  def test_page_anonymous_visit_from_other_language
    p = create_page :language => globalize_languages(:german)
    assert_not_equal p.language, Locale.base_language
    get :page, :page => p.page_name, :id => users(:quentin).id
    assert_response :success
    assert_template 'page.rhtml'
    assert_no_tag :tag => 'a', :content => 'edit page'
    assert_no_tag :tag => 'a', :content => 'create page'
    assert_tag :tag => 'div', :content => p.data
  end

  def test_page_owner_visits
    p = create_page
    login_as :quentin
    get :page, :page => p.page_name, :id => users(:quentin).id
    assert_response :success
    assert_template 'page.rhtml'
    assert_tag :tag => 'a', :content => 'edit article'
    assert_tag :tag => 'a', :content => 'create article'
  end

  def test_edit_requires_correct_user
    p = create_page
    get :edit_page, :page => p.page_name, :id => users(:quentin).id
    assert_access_denied
    login_as :editor
    get :edit_page, :page => p.page_name, :id => users(:quentin).id
    assert_access_denied
  end

  def test_edit_sets_editor
    p = create_page :user => users(:editor)
    assert_equal users(:editor), Page.find(p.id).user
    login_as :quentin
    post :update_page, 
      :page => p.page_name, 
      :id => users(:quentin).id, 
      :edited_page => {
        :data => 'Just testing...',
        :accept_license => '1'
      }
    assert_redirected_to :action => 'page', :page => p.page_name, :id => @quentin.id
    assert_equal 'Just testing...', Page.find(p.id).data
    assert_equal users(:quentin), Page.find(p.id).user
  end

  def test_changelog
    p = create_page
    login_as :quentin
    post :update_page, 
      :page => p.page_name, 
      :id => users(:quentin).id, 
      :edited_page => {
        :data => 'Just testing...',
        :accept_license => '1'
      }
    get :changelog, :id => @quentin.id, :page => p.page_name
    assert_response :success
    assert_tag :tag => 'li', :content => 'Revision 1', :child => { :tag => 'a', :content => 'quentin' }
    assert_tag :tag => 'li', :content => 'Revision 2', :child => { :tag => 'a', :content => 'quentin' }
  end

  def test_view_diff
    p = create_page
    p.data = 'version 2'
    p.accept_license_and_save!
    get :view_diff, :page => p.page_name, :id => users(:quentin).id, :from => '1', :to => '2'
    assert_response :success
    assert assigns(:version1)
    assert assigns(:version2)
  end

  def test_issue_116
    p = create_page :data => "link with alternate title: [[ch:15|James Kirk]]"
    get :page, :page => p.page_name, :id => users(:quentin).id
    assert_tag :tag => 'a', :content => 'James Kirk'

    p = create_page :data => "link with alternate title: [[ch:15:Additional Page 1|Alternativer Titel]]", 
                    :page_name => 'Another page'
    get :page, :page => p.page_name, :id => users(:quentin).id
    assert_tag :tag => 'a', :content => 'Alternativer Titel'

    p.data = "link to new page: [[ch:15:New Page]]"
    p.accept_license_and_save!
    get :page, :page => p.page_name, :id => users(:quentin).id
    assert_tag :tag => 'a', :content => 'New Page'

    p.data = "link to new page with alternate title: [[ch:15:New Page|Alternativer Titel]]"
    p.accept_license_and_save!
    get :page, :page => p.page_name, :id => users(:quentin).id
    assert_tag :tag => 'a', :content => 'Alternativer Titel'
  end

  ########## helper methods
   
  def create_page(params = {})
    p = nil
    assert_difference Page, :count do
      p = Page.create!(params.reverse_merge(:data => "Star-wars rocks", 
                                            :related_object => users(:quentin), 
                                            :user => users(:quentin),
                                            :language => Locale.base_language,
                                            :page_name => "MyPage"))
    end
    p
  end
end
