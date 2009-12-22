require File.dirname(__FILE__) + '/../test_helper'
require 'year_controller'

# Re-raise errors caught by the controller.
class YearController; def rescue_action(e) raise e end; end

class YearControllerTest < Test::Unit::TestCase
  fixtures :movies

  def setup
    @controller = YearController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_index
    get :index, :id => 1971
    assert_equal 1, assigns(:results).size
    assert_response :success
  end
end
