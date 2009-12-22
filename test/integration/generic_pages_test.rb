require "#{File.dirname(__FILE__)}/../test_helper"

class GenericPagesTest < ActionController::IntegrationTest
  fixtures :globalize_languages, :users, :contents

  def test_anonymous
    new_session do |s|
      s.get '/content/Imprint'
      s.assert_response :success
      assert_equal 'Imprint', s.assigns(:page).page_name
      s.assert_no_tag 'a', :content => 'edit page'
      s.get '/content/Imprint/edit_page'
      s.assert_redirected_to :controller => 'account', :action => 'login'
    end
  end

  def test_admin
    new_session_as users(:admin), 'test' do |s|
      s.get '/content/Imprint'
      s.assert_response :success
      assert_equal 'Imprint', s.assigns(:page).page_name
      s.assert_tag 'a', :content => 'edit page', :attributes => { :href => '/content/Imprint/edit_page' }
      s.get '/content/Imprint/edit_page'
      s.assert_response :success
    end
  end
end
