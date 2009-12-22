require File.dirname(__FILE__) + '/../test_helper'

# Re-raise errors caught by the controller.
class ApplicationController; def rescue_action(e) raise e end; end
class DummyController < ApplicationController
  before_filter :admin_required , :only => [ :for_admins ]
  before_filter :editor_required, :only => [ :for_editors ]
  before_filter :login_required,  :only => [ :for_registered_users ]

  def public
    render :text => 'hello'
  end
  def for_registered_users
    render :text => 'hello'
  end
  def for_editors
    render :text => 'hello'
  end
  def for_admins
    render :text => 'hello'
  end
end

class ApplicationControllerTest < Test::Unit::TestCase

  fixtures :users
    
  def setup
    @controller = DummyController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_public
    [ nil, :quentin, :editor, :admin ].each do |user|
      login_as user unless user.nil?
      get :public
      assert_success
    end
  end

  def test_login_required
    get :for_registered_users
    assert_access_denied

    [ :quentin, :editor, :admin ].each do |user|
      login_as user
      get :for_registered_users
      assert_success
    end
  end

  def test_editor_required
    get :for_editors
    assert_access_denied

    login_as :quentin
    get :for_editors
    assert_access_denied

    login_as :editor
    get :for_editors
    assert_success
  end

  def test_admin_required
    get :for_admins
    assert_access_denied

    login_as :quentin
    get :for_admins
    assert_access_denied

    login_as :admin
    get :for_admins
    assert_success
  end

  protected

  def assert_access_denied
    assert_redirected_to :controller => 'account', :action => 'login'
  end
  def login_as(user)
    @controller = DummyController.new # need to reset @current_user instance var
    @request.session[:user] = (user.is_a?(Symbol) ? users(user) : user).id
  end

end

