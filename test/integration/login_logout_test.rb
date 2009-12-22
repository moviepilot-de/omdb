require "#{File.dirname(__FILE__)}/../test_helper"

class LoginLogoutTest < ActionController::IntegrationTest
  fixtures :movies, :categories, :jobs, :people, :name_aliases, :globalize_languages, :users
  
  def test_login_logout_links
    new_session do |s|
      s.goto_movie
      s.assert_tag :tag => "a", :content => "Login".t
    
      s.login_with :login => users(:admin).login, :password => "test"
    
      assert !s.response.body.include?("Login".t)
      assert s.response.body.include?("Logout".t)
      assert s.response.body.include?("My Profile".t)
      
      s.goto_category(Category.find(301))
      s.logout
    
      assert s.response.body.include?("Login".t)
      assert !s.response.body.include?("Logout".t)
      assert !s.response.body.include?("My Profile".t)
    end
  end

  def test_login_should_set_users_language
    # quentin has selected german as his language
    new_session do |s|
      s.goto_movie
      s.assert_equal Language.find(1819), s.request.session[:language]
      s.login_with :login => users(:quentin).login, :password => "test"
      s.assert_equal Language.find(1556), s.request.session[:language]
    end
    # editor has no language set, should keep the current one after login
    new_session do |s|
      s.goto_movie
      s.assert_equal Language.find(1819), s.request.session[:language]
      s.login_with :login => users(:editor).login, :password => "test"
      s.assert_equal Language.find(1819), s.request.session[:language]
    end
  end

  def test_issue_177
    new_session_as(users(:admin), 'test') do |s|
      s.goto_movie
      [:goto_movie, :goto_person].each do |m|
        s.send m
        s.assert_tag :tag => "a", :content => "Logout".t
        s.assert_tag :tag => "a", :content => "My Profile".t
      end
      [1, 301].each do |cat|
        s.goto_category(Category.find(cat))
        s.assert_tag :tag => "a", :content => "Logout".t
        s.assert_tag :tag => "a", :content => "My Profile".t
      end
      s.logout
    end
  end

end
