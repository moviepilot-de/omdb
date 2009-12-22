require "#{File.dirname(__FILE__)}/../test_helper"

class PageCachingTest < ActionController::IntegrationTest
  fixtures :globalize_languages, :movies, :categories, :jobs, :users, :contents, :people, :casts

  class << PageCacheSweeper.instance
      def delete(path, locales = LOCALES)
        LOGGER.info "Expired page: #{path}"
        ActionController::Base.test_page_expired << path
      end
  end


  def setup
    @movie = movies(:king_kong)
    @person = people(:people_133)
  end
  
  def test_movie_page_caching_anonymous
    new_session do |s|
      pages = pages_for_movie @movie.id
      assert_cache_pages *pages
      urls = @movie.people.map { |p| "person/#{p.id}" }
      urls << @movie.categories.map { |c| "encyclopedia/category/#{c.id}" }
      assert_expire_pages('movie/254', *urls.flatten ) do |*urls|
        @movie.save
      end
      job_urls = @person.jobs.map {|j|"encyclopedia/job/#{j.id}"}
      assert_expire_pages('movie/254', 'person/3497', *job_urls) do |*urls|
        @person.save
      end
    end
  end

  def test_expire_movie_index_on_new_movie
    new_session do |s|
      assert_cache_pages '/movie'
      assert_expire_pages('movie.html') do |*urls|
        xml_http_request '/movie/create', :movie => { :name => 'new movie', :class => "Movie" }
      end
    end
  end

  def test_movie_page_caching_logged_in
    new_session_as users(:quentin), 'test' do |s|
    end
  end

  protected
  def pages_for_movie(id)
    [ '', '/cast' ].map { |action| "/movie/#{id}#{action}" }
  end
end
