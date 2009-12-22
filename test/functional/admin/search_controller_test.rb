require File.dirname(__FILE__) + '/../../test_helper'
require 'admin/search_controller'

# Re-raise errors caught by the controller.
class Admin::SearchController; def rescue_action(e) raise e end; end

class Admin::SearchControllerTest < Test::Unit::TestCase
  def setup
    @controller = Admin::SearchController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
