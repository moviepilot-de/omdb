require File.dirname(__FILE__) + '/../test_helper'
require 'reference_controller'

# Re-raise errors caught by the controller.
class ReferenceController; def rescue_action(e) raise e end; end

class ReferenceControllerTest < Test::Unit::TestCase
  fixtures :movies, :movie_references, :casts, :people
  
  def setup
    @controller = ReferenceController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_random_reference
    get :random
    assert_response :success
  end
end
