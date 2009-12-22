require File.dirname(__FILE__) + '/../test_helper'
require 'company_controller'
require 'pp'

# Re-raise errors caught by the controller.
class CompanyController; def rescue_action(e) raise e end; end

class CompanyControllerTest < Test::Unit::TestCase
  include Arts
  include TestOmdbHelper

  fixtures :companies, :movies, :production_companies, :contents, :jobs, :categories

  # Test the basic views for a company
  view_test_for :company, :tri_star
  view_test_for :company, :tri_star, :action => :top_movies, :template => 'top_movies.rhtml', :common_template => true
  view_test_for :company, :tri_star, :action => :blockbuster, :template => 'blockbuster.rhtml', :common_template => true
  view_test_for :company, :tri_star, :action => :statistics, :template => 'statistics.rhtml', :common_template => true

  abstract_test_for :company, :tri_star, :tri_star_abstract

  # test wiki functions
  view_page_tests_for        :company, :tri_star
  write_page_tests_for       :company, :tri_star
  rename_page_tests_for      :company, :tri_star
  page_destruction_tests_for :company, :tri_star
  page_versioning_tests_for  :company, :tri_star
  rss_link_tests_for         :company, :tri_star
  index_page_tests_for       :company, :el_deseo


  def setup
    @controller = CompanyController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_truth
    assert true
  end

  def test_movies_include_oliver_twist
    get :movies, :id => companies(:tri_star).id
    assert_success
    assert_tag :tag => "a",
        :attributes => { :href => "/movie/" + movies(:oliver_twist).id.to_s }
  end

  def test_ruins
    get :ruins
    assert_success
    assert_template 'ruins.rhtml'
    assert_tag :tag => "a",
        :attributes => { :href => "/encyclopedia/company/" + companies(:benq).id.to_s }
  end
  
  def test_destroy
    assert_difference Company, :count, -1 do
      login_as :admin
      post :destroy, :id => companies(:el_deseo).id
      assert_redirect
    end
  end
  
  def test_destroy_without_login
    assert_no_difference Company, :count do
      post :destroy, :id => companies(:avon_production).id
    end
    assert_redirect
    assert Company.find( companies(:avon_production).id )
  end
end
