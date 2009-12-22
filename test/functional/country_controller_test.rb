require File.dirname(__FILE__) + '/../test_helper'
require 'country_controller'
require 'pp'

# Re-raise errors caught by the controller.
class CountryController; def rescue_action(e) raise e end; end

class CountryControllerTest < Test::Unit::TestCase
  include TestOmdbHelper

  fixtures :globalize_countries, :movies, :categories, :jobs, :people, 
           :name_aliases, :movie_countries, :contents

  set_fixture_class(:globalize_countries => "Country")
  alias countries globalize_countries

  # Test the basic views for a country
  view_test_for :country, :usa, :action => :index, :template => 'overview.rhtml'
  view_test_for :country, :usa, :action => :movies, :template => 'movies.rhtml', :common_template => true
  view_test_for :country, :usa, :action => :statistics, :template => 'statistics.rhtml', :common_template => true

  # Test for a country without any movies
  view_test_for :country, :somalia, :action => :index, :template => 'overview.rhtml', :fetch_method => :globalize_countries

  abstract_test_for :country, :usa, :usa_abstract, :fetch_method => :globalize_countries, :klass => Country

  image_test_for :country, :usa, :fetch_method => :globalize_countries
  
  edit_aliases_test_for :country, :usa, "Die grosse Ignoranz"

  def setup
    @controller = CountryController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # test wiki functions
  view_page_tests_for        :country, :usa
  write_page_tests_for       :country, :usa
  rename_page_tests_for      :country, :usa
  page_destruction_tests_for :country, :usa
  page_versioning_tests_for  :country, :usa
  rss_link_tests_for         :country, :usa
  index_page_tests_for       :country, :france

end