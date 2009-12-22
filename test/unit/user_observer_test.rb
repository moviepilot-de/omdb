require File.dirname(__FILE__) + '/../test_helper'

class UserObserverTest < Test::Unit::TestCase
  fixtures :users

  def setup
    @o = UserObserver.instance
    @emails = ActionMailer::Base.deliveries
    @emails.clear
  end

  def test_send_activation_mail
    u = create_user
    assert_difference @emails, :size do
      @o.after_create(u)
    end
  end

  def test_send_welcome_mail
    u = create_user
    # not active, no mail
    assert_no_difference @emails, :size do
      @o.after_save(u)
    end
    # activate
    u.activate
    assert_difference @emails, :size do
      @o.after_save(u)
    end
    # already activated, so no mail
    assert_no_difference @emails, :size do
      @o.after_save(users(:quentin))
    end
  end

  def test_send_password_reset_mail
    u = users(:quentin)
    # no forgotten pwd, no mail
    assert_no_difference @emails, :size do
      @o.after_save(u)
    end
    users(:quentin).forgot_password
    assert_difference @emails, :size do
      @o.after_save(u)
    end
  end


  protected
    def create_user(options = {})
      User.create!(options.merge(:login => 'newuser', 
                                 :password => 'pass', 
                                 :password_confirmation => 'pass', 
                                 :email => 'user@host.com'))
    end
end


