require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase
  fixtures :users

  def test_wiki_index
    assert p = users(:quentin).wiki_index(Locale.base_language)
    assert_equal 'index', p.page_name
  end

  def test_set_flags
    u = User.create!(:login => 'newuser', :password => 'test', :password_confirmation => 'test', :email => 'user@host.com', :is_admin => '1', :is_editor => '1', :is_chiefeditor => '1') # check protected attributes
    assert !u.is_editor?
    assert !u.is_chiefeditor?
    assert !u.is_admin?

    u.is_chiefeditor = true
    u.save
    assert u.is_editor?
    assert u.is_chiefeditor?
    assert !u.is_admin?
    
    u.destroy
    u = User.create!(:login => 'newuser', :password => 'test', :password_confirmation => 'test', :email => 'user@host.com')
    u.is_admin = true
    u.save
    assert u.is_editor?
    assert u.is_chiefeditor?
    assert u.is_admin?

    u.destroy
    u = User.create!(:login => 'newuser', :password => 'test', :password_confirmation => 'test', :email => 'user@host.com')
    u.is_editor = true
    u.save
    assert u.is_editor?
    assert !u.is_chiefeditor?
    assert !u.is_admin?
  end

  def test_should_create_user
    assert_difference User, :count do
      user = create_user
      assert !user.new_record?, "#{user.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_login
    assert_no_difference User, :count do
      u = create_user(:login => nil)
      assert u.errors.on(:login)
    end
  end

  def test_should_require_password
    assert_no_difference User, :count do
      u = create_user(:password => nil)
      assert u.errors.on(:password)
    end
  end

  def test_should_require_password_confirmation
    assert_no_difference User, :count do
      u = create_user(:password_confirmation => nil)
      assert u.errors.on(:password_confirmation)
    end
  end

  def test_should_require_email
    assert_no_difference User, :count do
      u = create_user(:email => nil)
      assert u.errors.on(:email)
    end
  end

  def test_should_reset_password
    users(:quentin).update_attributes(:password => 'new password', :password_confirmation => 'new password')
    assert_equal users(:quentin), User.authenticate('quentin', 'new password')
  end

  def test_should_not_rehash_password
    users(:quentin).update_attributes(:login => 'quentin2')
    assert_equal users(:quentin), User.authenticate('quentin2', 'test')
  end

  def test_should_authenticate_user
    assert_equal users(:quentin), User.authenticate('quentin', 'test')
  end

  def test_should_not_authenticate_not_activated_user
    assert_nil User.authenticate('aaron', 'test')
  end

  def test_should_set_remember_token
    users(:quentin).remember_me
    assert_not_nil users(:quentin).remember_token
    assert_not_nil users(:quentin).remember_token_expires_at
  end

  def test_should_unset_remember_token
    users(:quentin).remember_me
    assert_not_nil users(:quentin).remember_token
    users(:quentin).forget_me
    assert_nil users(:quentin).remember_token
  end

  def test_should_activate_user
    users(:aaron).activate
    assert_not_nil users(:aaron).activated_at
    assert_nil users(:aaron).activation_code
    # login should be possible now
    assert_equal users(:aaron), User.authenticate('aaron', 'test')
  end
  
  protected
    def create_user(options = {})
      User.create({ :login => 'quire', :email => 'quire@example.com', :password => 'quire', :password_confirmation => 'quire' }.merge(options))
    end
end

