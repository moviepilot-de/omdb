require File.dirname(__FILE__) + '/test_helper'

class AssertCookieTest < Test::Unit::TestCase
  include Test::Unit
  
  def setup
    cookies['apples']       = CGI::Cookie.new 'name' => 'apples', 'value' => 'pies'
    cookies['pies']         = CGI::Cookie.new 'name' => 'pies', 'value' => ['lemon', 'apple', 'marionberry', 'strawberry']
    cookies['secret']       = CGI::Cookie.new 'name' => 'secret', 'secure' => true
    cookies['open_secret']  = CGI::Cookie.new 'name' => 'open_secret'
    cookies['limited_time'] = CGI::Cookie.new 'name' => 'limited_time',
        'expires' => Time.parse('20 Jan 2010')
    cookies['hiking']       = CGI::Cookie.new 'name' => 'hiking', 'path' => '/yellow/brick/road'
    cookies['planet_argon'] = CGI::Cookie.new 'name' => 'planet_argon', 'domain' => 'planetargon.com'
  end
  
  def cookies
    @cookies ||= {}
  end
  
  def test_assertion_cookie_does_not_exist_should_pass_when_cookie_not_found
    assert_pass { assert_no_cookie :vapor }
  end
  
  def test_assertion_cookie_does_not_exist_should_fail_when_cookie_found
    assert_fail { assert_no_cookie :apples }
  end
  
  def test_assertion_cookie_exists_should_fail_when_cookie_not_found
    assert_fail { assert_cookie :cauliflower }
  end
  
  def test_assertion_cookie_exists_should_pass_when_cookie_found
    assert_pass { assert_cookie :apples }
  end
  
  def test_assertion_cookie_value_should_pass_when_block_returns_true
    assert_pass { assert_cookie :apples, :value => lambda { true } }
  end
  
  def test_assertion_cookie_value_should_fail_when_block_returns_false
    assert_fail { assert_cookie :apples, :value => lambda { false } }
  end
  
  def test_assertion_cookie_value_should_pass_when_value_found_in_cookie_values
    assert_pass { assert_cookie :pies, :value => 'apple' }
  end
  
  def test_assertion_cookie_value_should_fail_when_value_not_found_in_cookie_values
    assert_fail { assert_cookie :pies, :value => 'mince meat' }
  end
  
  def test_assertion_cookie_value_should_pass_when_value_from_array_found_in_cookie_values
    assert_pass { assert_cookie :pies, :value => ['apple', 'lemon', 'strawberry'] }
  end

  def test_assertion_cookie_value_should_fail_when_value_from_array_not_found_in_cookie_values
    assert_fail { assert_cookie :pies, :value => ['bread', 'butter'] }
  end
  
  def test_assertion_cookie_path_should_pass_when_paths_are_equal
    assert_pass { assert_cookie :hiking, :path => '/yellow/brick/road' }
  end
  
  def test_assertion_cookie_path_should_fail_when_paths_are_not_equal
    assert_fail { assert_cookie :hiking, :path => '/bright/red/glow' }
  end
  
  def test_assertion_cookie_path_should_pass_when_block_returns_true
    assert_pass { assert_cookie :apples, :path => lambda { true } }
  end
  
  def test_assertion_cookie_path_should_fail_when_block_returns_false
    assert_fail { assert_cookie :apples, :path => lambda { false } }
  end
  
  def test_assertion_cookie_domain_should_pass_when_domains_are_equal
    assert_pass { assert_cookie :planet_argon, :domain => 'planetargon.com' }
  end
  
  def test_assertion_cookie_domain_should_fail_when_domains_are_not_equal
    assert_fail { assert_cookie :planet_argon, :domain => 'google.com' }
  end
  
  def test_assertion_cookie_domain_should_pass_when_block_returns_true
    assert_pass { assert_cookie :apples, :domain => lambda { true } }
  end
  
  def test_assertion_cookie_domain_should_fail_when_block_returns_false
    assert_fail { assert_cookie :apples, :domain => lambda { false } }
  end

  def test_assertion_cookie_expires_should_pass_when_expires_are_equal
    assert_pass { assert_cookie :limited_time, :expires => Time.parse('20 Jan 2010') }
  end
  
  def test_assertion_cookie_expires_should_fail_when_expires_are_not_equal
    assert_fail { assert_cookie :limited_time, :expires => Time.parse('1 Jan 1999') }
  end
  
  def test_assertion_cookie_expires_should_pass_when_block_returns_true
    assert_pass { assert_cookie :apples, :expires => lambda { true } }
  end
  
  def test_assertion_cookie_expires_should_fail_when_block_returns_false
    assert_fail { assert_cookie :apples, :expires => lambda { false } }
  end
  
  def test_assertion_cookie_secure_should_pass_when_block_returns_true
    assert_pass { assert_cookie :apples, :secure => lambda { true } }
  end
  
  def test_assertion_cookie_secure_should_fail_when_block_returns_false
    assert_fail { assert_cookie :apples, :secure => lambda { false } }
  end
  
  def test_assertion_cookie_is_secure_should_pass_when_cookie_is_secure
    assert_pass { assert_cookie :secret, :secure => true }
  end
  
  def test_assertion_cookie_is_secure_should_fail_when_cookie_is_not_secure
    assert_fail { assert_cookie :open_secret, :secure => true }
  end
end
