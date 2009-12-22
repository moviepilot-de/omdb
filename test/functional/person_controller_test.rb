require File.dirname(__FILE__) + '/../test_helper'
require 'person_controller'

# Re-raise errors caught by the controller.
class PersonController; def rescue_action(e) raise e end; end

class PersonControllerTest < Test::Unit::TestCase
  include TestOmdbHelper

  fixtures :people, :movies, :contents, :jobs, :casts

  # Test the basic views for a person
  view_test_for :person, :naomi_watts
  view_test_for :person, :naomi_watts, :action => :filmography, :template => 'filmography.rhtml'
  view_test_for :person, :naomi_watts, :action => :statistics, :template => 'statistics.rhtml', :common_template => true
  view_test_for :person, :naomi_watts, :action => :destroy, :response => 0
  view_test_for :person, :naomi_watts, :action => :destroy, :response => :redirect, :method => :post
  view_test_for :person, :naomi_watts, :action => :update_facts, :response => 0

  view_test_for :person, :naomi_watts, :action => :info, :template => 'info.rhtml', :xhr => true do |this|
    this.assert_tag :tag => 'h4', :content => this.people(:naomi_watts).name
  end

  abstract_test_for :person, :naomi_watts, :naomi_watts_abstract
  abstract_test_for :person, :trine_dryholm, nil
  
  edit_aliases_test_for :person, :naomi_watts, "Kleene Schnecke", :language_independent => true

  image_test_for :person, :naomi_watts

  def setup
    @controller = PersonController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def teardown
    SearchObserver.instance.cleanup
  end

  # test wiki functions
  view_page_tests_for        :person, :naomi_watts
  write_page_tests_for       :person, :naomi_watts
  rename_page_tests_for      :person, :naomi_watts
  page_destruction_tests_for :person, :naomi_watts
  page_versioning_tests_for  :person, :naomi_watts
  rss_link_tests_for         :person, :naomi_watts
  index_page_tests_for       :person, :china_doll


  def test_orphans
    get :orphans
    assert_response :success
    assert_template 'orphans.rhtml'
    assert_tag :tag => "a",
        :attributes => { :href => "/person/#{people(:david_hasselhoff).id}" }
  end
  
  def test_merge_unauthorized
    post :merge, :id => people(:jack_peterson).id, :people => [ people(:people_001).id, people(:people_299).id ]
    assert_access_denied
  end
  
  def test_merge
    login_as :admin
    post :merge, :id => people(:jack_peterson).id, :people => [ people(:people_001).id, people(:people_299).id ]
    assert_response :redirect
    assert_redirected_to :action => :index
  end
  
  def test_portal
    get :index
    assert_response :success
    assert_template 'index.rhtml'
  end
  
  def test_destroy_orphans_without_login
    post :destroy_orphans
    assert_access_denied  
    assert (Person.find_orphans.size > 0)
  end
  
  def test_destroy_orphans
    login_as :admin
    assert (Person.find_orphans.size > 0)
    post :destroy_orphans
    assert_response :redirect
    assert (Person.find_orphans.size == 0)
  end
  
  def test_destroy_person_and_search
    login_as :admin
    post :destroy, :id => people(:willy_harlander).id
    assert_response :redirect
    results = Searcher.search('Willy Harlander').collect {|o| o.to_o }
    assert !results.include?(people(:willy_harlander))
  end

end
