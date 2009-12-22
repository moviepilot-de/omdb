require File.dirname(__FILE__) + '/test_helper'

class AkismetController < ActionController::Base; include Akismet; def rescue_action(e) raise e end; end

class AkismetTest < Test::Unit::TestCase

  def setup
    @controller = AkismetController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end
  
  def test_should_verify_key
    assert !@controller.has_verified_akismet_key?
    @controller.verify_akismet_key
    assert @controller.has_verified_akismet_key?
  end

  def test_should_not_approve_known_spam
    assert @controller.is_spam?(:comment_author => 'viagra-test-123', 
                                            :user_ip => @request.remote_ip, 
                                            :user_agent => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.8.1) Gecko/20061010 Firefox/2.0', 
                                            :referrer => 'http://127.0.0.1/',
                                            :comment_content => 'this comment_author triggers known spam'
                                          )
  end
  
  def test_should_approve_something_harmless
    assert !@controller.is_spam?(:comment_author => 'Rails Tester', 
                                            :user_ip => @request.remote_ip, 
                                            :user_agent => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.8.1) Gecko/20061010 Firefox/2.0', 
                                            :referrer => 'http://127.0.0.1/',
                                            :comment_content => 'Hi, I really like your blog.'
                                          )
  end
  
end
