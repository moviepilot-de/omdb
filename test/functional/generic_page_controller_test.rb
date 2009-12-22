require File.dirname(__FILE__) + '/../test_helper'
require 'generic_page_controller'

# Re-raise errors caught by the controller.
class GenericPageController; def rescue_action(e) raise e end; end

class GenericPageControllerTest < Test::Unit::TestCase
  fixtures :contents

  def setup
    @controller = GenericPageController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_page
    get :page, :page => 'Imprint'
    assert_response :success
    assert_tag :tag => 'h2', :content => 'Imprint'
  end

  def test_edit
    get :edit_page, :page => 'Imprint'
    assert_access_denied
    login_as :admin
    get :edit_page, :page => 'Imprint'
    assert_response :success

    post :update_page, :page => 'Imprint', :edited_page => { :data => 'This is the new Imprint', :accept_license => '1' }
    assert_redirected_to :action => 'page', :page => 'Imprint'
  end


end
