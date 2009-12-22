require "#{File.dirname(__FILE__)}/../test_helper"

class PagesTest < ActionController::IntegrationTest
  fixtures :globalize_languages, :movies, :categories, :jobs, :users, :contents, :people, :casts

  def setup
    @m = movies(:king_kong)
  end
  
  def test_destroy_page
    new_session_as :admin do |s|
      assert_difference Content, :count, -1 do
        s.post "/movie/#{@m.id}/destroy_page/Additional Page 1"
      end
    end
  end

  def test_destroy_page_requires_admin
    new_session do |s|
      assert_no_difference Content, :count do
        s.post "/movie/#{@m.id}/destroy_page/Additional Page 1"
      end
    end
  end

end

