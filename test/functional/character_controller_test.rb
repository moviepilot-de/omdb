require File.dirname(__FILE__) + '/../test_helper'
require 'character_controller'

# Re-raise errors caught by the controller.
class CharacterController; def rescue_action(e) raise e end; end

class CharacterControllerTest < Test::Unit::TestCase
  include TestOmdbHelper

  fixtures :people, :movies, :casts, :characters, :contents
  
  view_test_for :character, :indiana_jones
  view_test_for :character, :indiana_jones, :action => :portrayed, :template => 'portrayed.rhtml'
  view_test_for :character, :indiana_jones, :action => :movies, :template => 'movies.rhtml', :comon_template => true

  abstract_test_for :character, :indiana_jones, :indiana_jones_abstract
  
  image_test_for :character, :indiana_jones  

  edit_aliases_test_for :character, :indiana_jones, "Indy"

  def setup
    @controller = CharacterController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  view_test_for :character, :dracula

  # test wiki functions
  view_page_tests_for        :character, :indiana_jones
  write_page_tests_for       :character, :indiana_jones
  rename_page_tests_for      :character, :indiana_jones
  page_destruction_tests_for :character, :indiana_jones
  page_versioning_tests_for  :character, :indiana_jones
  rss_link_tests_for         :character, :indiana_jones
  index_page_tests_for       :character, :worf

end
