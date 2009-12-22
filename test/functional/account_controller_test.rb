require File.dirname(__FILE__) + '/../test_helper'
require 'account_controller'

# Re-raise errors caught by the controller.
class AccountController; def rescue_action(e) raise e end; end

class AccountControllerTest < Test::Unit::TestCase

  fixtures :users

  def setup
    @controller = AccountController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @emails = ActionMailer::Base.deliveries
    @emails.clear
    @request.session[:return_to] = '/original/url'
  end

  def test_signup_form
    get :signup
    assert_success
  end

  def test_forgot_password
    get :forgot_password
    assert_success

    post :forgot_password, :email => 'i_dont_exist'
    assert_success
    assert_tag :tag => 'p', :content => 'Could not find a user with that email address.'

    post :forgot_password, :email => users(:quentin).email
    assert_success
    assert_tag :tag => 'p', :content => 'The password reset link has been sent to your email address.'
    assert_equal 1, @emails.size
    assert_equal users(:quentin).email, @emails.first.to.first
  end

  def test_reset_password_with_wrong_code
    get :reset_password
    assert_nil assigns(:user)
    assert_success
    assert_tag :tag => 'p', :content => 'The password reset link you clicked seems to be invalid.'
    assert_no_tag :tag => 'form', :attributes => { :action => /reset_password/ }

    get :reset_password, :id => 'invalid_code'
    assert_success
    assert_nil assigns(:user)
    assert_tag :tag => 'p', :content => 'The password reset link you clicked seems to be invalid.'
    assert_no_tag :tag => 'form', :attributes => { :action => /reset_password/ }

    post :reset_password, :password => 'new_pass', :password_confirmation => 'new_pass'
    assert_success
    assert_tag :tag => 'p', :content => 'The password reset link you clicked seems to be invalid.'
    assert_no_tag :tag => 'form', :attributes => { :action => /reset_password/ }
  end

  def test_reset_password
    post :forgot_password, :email => users(:quentin).email
    quentin = User.find(users(:quentin).id)
    assert_not_nil quentin.password_reset_code
    get :reset_password, :id => quentin.password_reset_code
    assert_success
    assert_tag :tag => 'form', :attributes => { :action => /reset_password/ }
    assert_not_nil User.find(quentin.id).password_reset_code

    post :reset_password, :id => quentin.password_reset_code, 
          :password => 'new_pass', 
          :password_confirmation => 'new_pas'
    assert_success
    assert_not_nil User.find(quentin.id).password_reset_code
    assert_tag :tag => 'form', :attributes => { :action => /reset_password/ }
    
    post :reset_password, :id => quentin.password_reset_code, 
          :password => 'new_pass', 
          :password_confirmation => 'new_pass'
    assert_redirected_to :action => 'login'
    assert_equal quentin, User.authenticate('quentin', 'new_pass')
    assert_nil User.find(quentin.id).password_reset_code
  end

  def test_should_login_and_redirect
    post :login, :login => 'quentin', :password => 'test'
    assert session[:user]
    assert_response :redirect
  end
  
  def test_should_login_and_redirect_xhr
    xhr :post, :login, :login => 'quentin', :password => 'test'
    assert session[:user]
    assert_success
    assert_rjs :redirect
  end

  def test_should_fail_login_and_not_redirect
    post :login, :login => 'quentin', :password => 'bad password'
    assert_nil session[:user]
    assert_response :success
    assert_template 'login.rhtml'
  end
  def test_should_fail_login_and_not_redirect_xhr
    xhr :post, :login, :login => 'quentin', :password => 'bad password'
    assert_nil session[:user]
    assert_response :success
    assert_template '_login_form.rhtml'
  end

  def test_should_allow_signup
    assert_difference User, :count do
      assert_difference @emails, :size do
        create_user
        assert_response :success
        assert_template 'success.rhtml'
      end
    end
  end

  def test_should_require_login_on_signup
    assert_no_difference User, :count do
      create_user(:login => nil)
      assert assigns(:user).errors.on(:login)
      assert_response :success
    end
  end

  def test_should_require_valid_login_on_signup
    assert_no_difference User, :count do
      create_user(:login => 'a bc')
      assert assigns(:user).errors.on(:login)
      assert_response :success
    end
  end

  def test_should_require_password_on_signup
    assert_no_difference User, :count do
      create_user(:password => nil)
      assert assigns(:user).errors.on(:password)
      assert_response :success
    end
  end

  def test_should_require_password_confirmation_on_signup
    assert_no_difference User, :count do
      create_user(:password_confirmation => nil)
      assert assigns(:user).errors.on(:password_confirmation)
      assert_response :success
    end
  end

  def test_should_require_email_on_signup
    assert_no_difference User, :count do
      create_user(:email => nil)
      assert assigns(:user).errors.on(:email)
      assert_response :success
    end
  end

  def test_should_logout
    login_as :quentin
    get :logout
    assert_nil session[:user]
    assert_response :redirect
  end

  def test_should_remember_me
    post :login, :login => 'quentin', :password => 'test', :remember_me => "1"
    assert_not_nil @response.cookies["auth_token"]
  end

  def test_should_not_remember_me
    post :login, :login => 'quentin', :password => 'test', :remember_me => "0"
    assert_nil @response.cookies["auth_token"]
  end
  
  def test_should_delete_token_on_logout
    login_as :quentin
    get :logout
    assert_equal @response.cookies["auth_token"], []
  end

  def test_should_login_with_cookie
    users(:quentin).remember_me
    @request.cookies["auth_token"] = cookie_for(:quentin)
    get :index
    assert @controller.send(:logged_in?)
  end

  def test_should_fail_cookie_login
    users(:quentin).remember_me
    users(:quentin).update_attribute :remember_token_expires_at, 5.minutes.ago.utc
    @request.cookies["auth_token"] = cookie_for(:quentin)
    get :index
    assert !@controller.send(:logged_in?)
  end

  def test_should_fail_cookie_login
    users(:quentin).remember_me
    @request.cookies["auth_token"] = auth_token('invalid_auth_token')
    get :index
    assert !@controller.send(:logged_in?)
  end

  def test_should_activate_user
    assert_nil User.authenticate('aaron', 'test')
    assert_difference @emails, :size do
      get :activate, :id => users(:aaron).activation_code
    end
    assert_equal users(:aaron), User.authenticate('aaron', 'test')
  end

  protected
    def create_user(options = {})
      post :signup, :user => { :login => 'quire', :email => 'quire@example.com', 
        :password => 'quire', :password_confirmation => 'quire' }.merge(options)
    end
    
    def auth_token(token)
      CGI::Cookie.new('name' => 'auth_token', 'value' => token)
    end
    
    def cookie_for(user)
      auth_token users(user).remember_token
    end
end
