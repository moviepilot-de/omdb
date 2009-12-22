require File.dirname(__FILE__) + '/../test_helper'
require 'session_controller'

# Re-raise errors caught by the controller.
class SessionController; def rescue_action(e) raise e end; end

class SessionControllerTest < Test::Unit::TestCase

  def setup
    @controller = SessionController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.session[:return_to] = '/movie'
  end
  def current_user
    @controller.send(:current_user)
  end
  
  def test_should_set_language_for_anonymous
    get :set_language, :language => '1556' # german
    assert_redirected_to '/movie'
    assert_equal Language.find(1556), @request.session[:language]
    assert_cookie :language, :value => 'de'
    assert_nil current_user.language

    @request.env['HTTP_REFERER'] = 'http://test.host/person/123'
    get :set_language, :language => '1819' # english
    assert_redirected_to 'http://test.host/person/123'
    assert_cookie :language, :value => 'en'
    assert_equal Language.find(1819), @request.session[:language]
    assert_nil current_user.language
  end

  def test_should_set_language_for_anonymous_xhr
    xhr :post, :set_language, :language => '1556' # german
    assert_success
    assert_rjs :redirect_to, '/movie'
    assert_equal Language.find(1556), @request.session[:language]
    assert_nil current_user.language

    @request.session[:return_to] = '/person'
    xhr :post, :set_language, :language => '1819' # english
    assert_success
    assert_rjs :redirect_to, '/person'
    assert_equal Language.find(1819), @request.session[:language]
    assert_nil current_user.language
  end

  def test_should_save_language_for_user
    login_as :quentin
    @request.session[:return_to] = '/movie'
    xhr :post, :set_language, :language => '1556' # german
    assert_success
    assert_rjs :redirect_to, '/movie'
    assert_equal Language.find(1556), @request.session[:language]
    assert_equal Language.find(1556), current_user.language
    assert_equal Language.find(1556), User.find(users(:quentin).id).language

    @request.session[:return_to] = '/person'
    xhr :post, :set_language, :language => '1819' # english
    assert_success
    assert_rjs :redirect_to, '/person'
    assert_equal Language.find(1819), @request.session[:language]
    assert_equal Language.find(1819), current_user.language
    assert_equal Language.find(1819), User.find(users(:quentin).id).language
  end

end

