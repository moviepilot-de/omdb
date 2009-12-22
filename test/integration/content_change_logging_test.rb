require "#{File.dirname(__FILE__)}/../test_helper"

class ContentChangeLoggingTest < ActionController::IntegrationTest
  fixtures :globalize_languages, :movies, :categories, :jobs, :users, :contents, :people, :casts

  def setup
    @movie = movies(:king_kong)
    @person = people(:people_133)
  end

  def test_create_movie_page_should_create_log_entry
    new_session_as :quentin do |s|
      assert_no_difference LogEntry, :count do
        s.get "/movie/#{@movie.id}/edit_page/neueseite"
        s.assert_response :success
      end
      assert_difference LogEntry, :count do
        s.post "/movie/#{@movie.id}/update_page/neueseite", 
               :edited_page => { :data => 'new page content', 
                                 :accept_license => '1', 
                                 :comment => 'comment text' }
      end
      s.assert_redirected_to "/movie/#{@movie.id}/page/neueseite"
      s.follow_redirect!
      s.assert_tag :tag => 'p', :content => 'new page content'
      @movie.reload
      assert_equal 1, @movie.log_entries.size
      le = @movie.log_entries.first
      assert ContentLogEntry === le
      assert_equal users(:quentin), le.user
      assert_equal '0', le.old_value
      assert_equal '1', le.new_value
      assert_equal users(:quentin).language, le.language
      assert_equal @movie.page('neueseite', users(:quentin).language).id, le.attribute.to_i

      s.check_history @movie
    end
  end
  
  def test_edit_movie_page_should_create_log_entry
    new_session_as :quentin do |s|
      m = @movie
      page = m.wiki_index(users(:quentin).language)

      assert_no_difference LogEntry, :count do
        s.get "/movie/#{@movie.id}"
        s.assert_response :success
        s.get "/movie/#{@movie.id}/edit_page/index"
        s.assert_response :success
      end

      assert_difference LogEntry, :count do
        s.post "/movie/#{@movie.id}/update_page/index", :edited_page => { :data => 'new page content', :accept_license => '1', :comment => 'comment text' }
      end
      s.assert_redirected_to "/movie/#{@movie.id}"
      s.follow_redirect!
      s.assert_tag :tag => 'p', :content => 'new page content'
      m.reload
      page.reload

      assert_equal 1, m.log_entries.size
      le = m.log_entries.first
      assert ContentLogEntry === le
      assert_equal users(:quentin).language, le.language
      assert_equal users(:quentin), le.user
      assert_equal page.id, le.attribute.to_i
      assert_equal page.version, le.new_value.to_i
      assert_equal page.version-1, le.old_value.to_i

      s.check_history @movie
    end
  end

  def new_session_as(user)
    super do |s|
      class << s
        def check_history(movie)
          get "/movie/#{movie.id}/history"
          assert_response :success
          assert_match /(created|changed) page/i, @response.body

          get "/session/set_language?language=1819"
          get "/movie/#{movie.id}/history"
          assert_response :success
          assert_equal 1819, assigns(:language).id
          assert_no_match /(created|changed) page/i, @response.body
        end
      end
      yield s
    end
  end

end

