require File.dirname(__FILE__) + '/../test_helper'
require 'movie_controller'
require 'pp'

# Re-raise errors caught by the controller.
class MovieController; def rescue_action(e) raise e end; end

class MovieControllerTest < Test::Unit::TestCase
  include Arts
  include TestOmdbHelper

  fixtures :movies, :movie_references, :contents, :people, :casts, 
           :movie_countries, :globalize_countries, :categories, 
           :name_aliases, :reviews, :companies, :reviews,
           :production_companies, :jobs, :movie_user_categories, :images

  
  # since the activerecord fixtures try to find the class name through the name 
  # of the fixture and througs the table name, we have to explicitely tell 
  # the class it needs to expand :movie_references to
  set_fixture_class(:movie_references => "Reference")

  # test wiki functions
  view_page_tests_for        :movie, :king_kong
  write_page_tests_for       :movie, :king_kong
  rename_page_tests_for      :movie, :king_kong
  page_destruction_tests_for :movie, :king_kong
  page_versioning_tests_for  :movie, :king_kong
  rss_link_tests_for         :movie, :king_kong
  trackback_test_for         :movie, :king_kong
  index_page_tests_for       :movie, :willy_wonka
  
  # Test Overview for Movie, Series, Episode
  view_test_for :movie, :king_kong
  view_test_for :movie, :star_trek_tng
  view_test_for :movie, :star_trek_tng_season_one
  view_test_for :movie, :encounter_at_farpoint

  view_test_for :movie, :king_kong, :action => :history, :template => 'history.rhtml'

  view_test_for :movie, :encounter_at_farpoint, :action => :destroy, :response => 0
  view_test_for :movie, :encounter_at_farpoint, :action => :destroy, :response => :redirect, :method => :post

  view_test_for :movie, :king_kong, :action => :display_categories, :xhr => true, :method => :post, :template => '_overview_categories.rhtml'
  view_test_for :movie, :king_kong, :action => :display_keywords, :xhr => true, :method => :post, :template => '_overview_plot_keywords.rhtml'

  view_test_for :movie, :king_kong, :action => :edit_facts, :xhr => true, :template => 'edit_facts.rhtml'
  view_test_for :movie, :king_kong, :action => :edit_categories, :xhr => true, :template => 'edit_categories.rhtml'
  view_test_for :movie, :king_kong, :action => :edit_keywords, :xhr => true, :template => 'edit_keywords.rhtml'
  

  view_test_for :movie, :batman_series, :action => :edit_children, :xhr => true, :template => 'edit_children.rhtml'

  view_test_for :movie, :king_kong, :action => :edit_references, :xhr => true, :template => 'edit_references.rhtml'
  view_test_for :movie, :king_kong, :action => :create_reference, :xhr => true, :template => '_new_reference_page_2.rhtml',
                                    :params => { :reference_class => Influence.to_s.underscore }
                                    
  view_test_for :movie, :batman_series, :action => :parts, :template => 'parts.rhtml'

#  view_test_for :movie, :king_kong, :action => :reviews, :template => 'reviews.rhtml' do |instance|
#    instance.assert_tag :tag => "div", :content => instance.reviews(:king_kong_review).data
#  end

  view_test_for :movie, :king_kong, :action => :cast, :template => 'cast.rhtml' do |instance|
   instance.assert_tag :tag => "a",
        :attributes => { :href => "/person/#{instance.people(:peter_jackson).id}" }
  end

  view_test_for :movie, :king_kong, :action => :page, :template => 'toc.rhtml' do |instance|
    instance.assert_tag :tag => "a", :content => 'more',
        :attributes => { :href => "/movie/254/page/Additional+Page+1" }
  end

  view_test_for :movie, :king_kong, :action => :info, :template => 'info.rhtml', :xhr => true do |instance|
    instance.assert_tag :tag => 'a', :content => instance.people(:peter_jackson).name
  end

  abstract_test_for :movie, :star_wars, :starwars_abstract
  abstract_test_for :movie, :encounter_at_farpoint, nil
  image_test_for :movie, :king_kong
  
  edit_aliases_test_for :movie, :king_kong, "Der grosse Affe"
  
  def setup
    @controller = MovieController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def teardown
    SearchObserver.instance.cleanup
    Searcher.close!
  end

  def test_changes_page
    login_as :editor
    get :changes
    assert_response :success
  end

  def test_update_children
    parent = movies(:batman_series)
    xhr :post, :update_children, :id => parent.id, :movies => [ movies(:movies_007).id, movies(:big_lebowski).id ]
    assert_response :success
    parent.reload
    assert_equal 2, parent.reload.children.size, parent.children.inspect
    assert parent.children.include?(movies(:movies_007))
    assert parent.children.include?(movies(:big_lebowski))

    xhr :post, :update_children, :id => parent.id, :movies => [ movies(:big_lebowski).id ]
    assert_response :success
    parent.reload
    assert_equal 1, parent.children.size
    assert parent.children.include?(movies(:big_lebowski))
  end

  def test_latest_movies_rss
    get :latest, :type => 'rss'
    assert_response :success
    assert_tag :tag => 'rss'
    assert_equal 6, assigns(:movies).size
  end

  def test_latest_movies_rss_link
    get :index, :id => movies(:star_wars).id
    assert_response :success
    assert_tag :tag => "link", 
               :attributes => { :href => %r{/movie/latest.xml} }
  end

  def abstract_to_long
    abstract = "1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
                1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
                1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
                1234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890"
    
    xhr :post, :set_abstract, :movie => movies(:star_wars), movie_abstract => abstract
    assert_success
    
    assert_equal movies(:star_wars).abstract.data, contents(:starwars_abstract).data
  end

  # Application controller test - 
  
  def test_content_negotiation_accept_language
    @request.env['HTTP_ACCEPT_LANGUAGE'] = 'de-DE'
    get :index, :id => movies(:king_kong).id
    assert_cookie :language, :value => 'de'
  end

  def test_content_negotiation_host
    @request.env['HTTP_ACCEPT_LANGUAGE'] = 'de-DE'
    @request.env['HTTP_HOST'] = 'en.omdb.org'
    get :index, :id => movies(:king_kong).id
    assert_cookie :language, :value => 'en'
  end

  def test_king_kong
    m = movies(:king_kong)
    p = contents(:king_kong_additional_page)
    assert_equal m, p.related_object
    get :page, :id => m.id
    assert_template 'toc.rhtml'
    assert_tag :tag => 'div', :attributes => { :id => 'content', :class => 'wiki-page' }
    assert_tag :tag => "a", :content => 'more', :attributes => { :href => "/movie/#{movies(:king_kong).id}/page/Additional+Page+1" }
  end

  def test_random_movie
    get :random
    assert_response :redirect
  end
  
  def test_invalid_id
    assert_raise ActiveRecord::RecordNotFound do
      get :index, :id => 1234567
    end
  end
  
  # Test views

  def test_movie_countries
    get :index, :id => movies(:king_kong).id
    assert_success
    assert_tag :tag => "a", :content => Country.find( 223 ).code
  end

  def test_portal_index
    get :index
    assert_response :success
  end
  
  def test_portal_bottom_100
    get :bottom
    assert_response :success
  end

  # Cast View Tests

  def test_activate_sorting
    type = "movie-3"
    xhr :get, :activate_cast_sorting, :type => type, :id => movies(:king_kong).id
    assert_success
    assert_rjs :sortable, type, :url => { :action => 'sort_department', :department => type.split(/-/).last }, :handle => 'handle'
  end
  

  # Test "New Movie" Action
  def test_new_movie_plain_request
    assert_no_difference Movie, :count do
      post :new, :movie => { :name => "Star Wars 2" }
      assert_redirected_to :action => :index
    end
  end
  
  def test_new_movie_xhtml_request
    xhr :post, :new
    assert_response :success
    assert_template 'new.rhtml'
  end
  
  def test_new_movie_xhr_via_series
    xhr :post, :new, :id => movies(:batman_series).id
    assert_response :success
    assert_template 'new_select_type.rhtml'
  end

  def test_new_movie_xhr_via_season
    xhr :post, :new, :id => movies(:star_trek_tng_season_one).id
    assert_response :success
    assert_template 'new_select_type.rhtml'
  end

  def test_new_movie_xhr_request_2
    xhr :post, :new, :movie => { :name => "Star Wars", :class => "Movie" }
    assert_response :success
    assert_template 'new_page2.rhtml'
  end

  def test_new_movie_xhr_request_3
    assert_difference Movie, :count do
      xhr :post, :new, :movie => { :name => "Star Wars", :class => "Movie" }, :continue => 'on'
    end
    assert_response :success
    movies = Movie.find_all_by_name( "Star Wars" )
    assert_equal 2, movies.size
    Indexer.delete_object movies[0].to_hash_args
    Indexer.delete_object movies[1].to_hash_args
  end

  def test_new_season
    xhr :post, :new, :movie => { :name => "TNG Season 2", :class => "Season" }, :parent_movie => movies(:star_trek_tng).id
    assert_response :success
    movies = Movie.find_all_by_name( "TNG Season 2" )
    assert_equal 1, movies.size
    assert_equal Season, movies.first.class
    Indexer.delete_object movies[0].to_hash_args
  end

  def test_create_movie_sets_creator
    name = "My Brand New Movie"
    login_as :quentin
    assert_difference Movie, :count do
      xhr :post, :new, :movie => { :name => name, :class => "Movie" }
    end
    assert_response :success
    movie = Movie.find_by_name( name )
    assert_equal movie.class, Movie
    assert_equal users(:quentin), movie.creator
    Indexer.delete_object movie.to_hash_args
  end

  def test_new_movie_xhr_and_create
    name = "My Brand New Movie"
    assert_difference Movie, :count do
      xhr :post, :new, :movie => { :name => name, :class => "Movie" }
    end
    assert_response :success
    movie = Movie.find_by_name( name )
    assert_equal movie.class, Movie
    assert movie.creator.anonymous?
    Indexer.delete_object movie.to_hash_args
  end

  def test_new_movie_xhr_and_create_alias
    name = "Brand New Movie"
    xhr :post, :new, :movie => { :name => name, :class => "Movie" }, :original_name_unknown => true
    assert_success
    movie = Movie.find_by_name( name )
    assert movie
    assert_equal( 1, movie.aliases.size, "remove name_aliases fixture with movie_id #{movie.id}" )
    assert movie.aliases.first.official_translation
    Indexer.delete_object movie.to_hash_args
  end
  
  
  # Test alias creation

  def test_create_official_alias
    title = "New Title for Batman"
    assert_equal [], movies(:batman).official_translation( Language.pick('en') )
    xhr :post, :update_facts, :id => movies(:batman).id, :select_alias => 'new', :new_alias => title
    assert_equal title, movies(:batman).official_translation(Language.pick('en')).first.name
  end

  def test_create_new_keyword_for_movie
    keyword_name = "The Force"
    @request.env["RAW_POST_DATA"] = keyword_name
    xhr :post, :add_new_keyword, :id => movies(:star_wars).id, :create => true
    assert_response :success
    assert_template "_overview_plot_keywords.rhtml"
    assert_equal 1, movies(:star_wars).plot_keywords.size
    assert_equal keyword_name, movies(:star_wars).plot_keywords.first.name
    assert_equal movies(:star_wars).plot_keywords.first.parent, Category.default_keyword_parent
  end

  def test_add_and_delete_category
    login_as :quentin
    movie = movies(:star_trek_tng_season_one)
    get :add_category, :id => movie.id, :category => "5"
    assert_success
    assert_equal 2, Movie.find(movie.id).categories.size
    xhr :post, :delete_category, :id => movie.id, :category => "5"
    assert_success
    assert_equal 1, Movie.find(movie.id).categories.size
  end
  
  def test_create_new_company_for_movie
    login_as :editor
    company_name = "Some New Company"
    movie = movies(:king_kong)
    xhr :post, :update_facts, :id => movie.id, :new_companies => [ company_name ]
    assert_success
    assert_equal company_name, movie.reload.companies.first.name
  end
  
  def test_display_category_vote_icons
    login_as :quentin
    xhr :get, :display_category_vote_icons, :id => movies(:big_lebowski).id
    assert_response :success
  end
  
  def test_display_keyword_vote_icons
    login_as :quentin
    xhr :get, :display_keyword_vote_icons, :id => movies(:big_lebowski).id
    assert_response :success
  end

  def test_add_category_without_login
    movie = movies(:big_lebowski)
    assert_difference MovieUserCategory, :count do
      get :add_category, :id => movie.id, 
                         :category => categories(:action).id
    end
    assert_response :success

    # Anonymous can add a category once, but we do not allow anonymous to
    # add more votes..
    assert_no_difference MovieUserCategory, :count do
      get :add_category, :id => movie.id, 
                         :category => categories(:action).id
    end
    assert_response :success
  end
    
#  def test_create_review_without_login
#    xhr :post, :create_review, :id => movies(:star_wars).id, :review => { :data => "This movie rocks!" }
#    assert_not_nil flash[:error]
#  end

#  def test_create_review_with_login
#    login_as :quentin
#    assert_difference Review, :count do
#      assert_difference Vote, :count do
#        xhr :post,
#            :create_review,
#            { :id => movies(:star_wars).id, :review => { :data => "This movie rocks!"}, :vote => { :vote => 1 } }
#      end
#    end
#    assert_response :success
#    assert_nil flash[:error]
    
#    assert(review = Review.find_by_movie_id(movies(:star_wars).id))
#    assert_equal "This movie rocks!", review.data
#  end
  
#  def test_new_review_with_existing_data
#    login_as :quentin
#    review_data = "This movie rocks!"
#    review = Review.create(:data => review_data, :user => users(:quentin), 
#                          :movie => movies(:star_wars), :rating => 1)
#    review.save!

#    xhr :get, :new_review, { :id => movies(:star_wars).id }
#    assert_success
    
#    assert_tag :tag => "textarea", :content => review_data
#  end
  
#  def test_new_review_without_login
#    xhr :get, :new_review, :id => movies(:star_wars).id
#    assert_success
#    assert_not_nil flash[:error]
#  end
  
#  def test_create_review_with_existing_data
#    login_as :quentin
    # create initial review
#    xhr :post,
#        :create_review,
#        { :id => movies(:star_wars).id, :review => { :data => "This movie rocks!", :rating => 1 } }
    # then update it
#    xhr :post,
#        :create_review,
#        { :id => movies(:star_wars).id, :review => { :data => "This movie sucks!", :rating => 1 } }
#    assert_success
#    review = Review.find_by_movie_id(movies(:star_wars).id)
#    assert_not_nil review
#    assert_equal "This movie sucks!", review.data
#  end
  
#  def test_reviews
    # prepare review, so that it has a real user
    #reviews(:spaceballs).update_attributes :user => User.admin
    
#    get :reviews, :id => movies(:star_wars).id
#    assert_success
#    assert_not_nil assigns(:reviews)
#    assert_not_nil assigns(:pages)
#    assert_equal 1, assigns(:pages).length
    
#    assert_template "reviews.rhtml"
#  end
  
  def test_assign_child
    post :assign_child, :id => movies(:batman_series).id, :movie => movies(:batman).id
    assert_success
    movies(:batman).reload
    assert_equal movies(:batman).parent, movies(:batman_series)
  end  
  
  

  def test_category_vote_button_no_login
    get :index, :id => movies(:king_kong).id
    assert_response :success
    assert_no_tag :tag => "a", :content => 'voting'
  end
  
  def test_category_vote_button_no_login
    login_as :quentin
    get :index, :id => movies(:king_kong).id
    assert_response :success
    assert_tag :tag => "a", :content => 'voting'
  end
  
  # the javascript call doesn't work
  def test_category_links_when_logged_in_and_not_voted
    login_as :quentin
    assert_difference MovieUserCategory, :count do
      get :add_category, { :id => movies(:star_wars).id, :category => categories(:action).id }
    end
    get :index,{ :id => movies(:star_wars).id }
  end
  
  def test_add_category_more_than_once
    login_as :quentin
    assert_difference MovieUserCategory, :count do
      post :add_category, { :id => movies(:star_wars).id, :category => categories(:action).id }
    end
    assert_response :success
    
    vote = MovieUserCategory.find_by_movie_id_and_category_id(movies(:star_wars).id, categories(:action).id)
    assert vote.is_a?(MovieUserCategory)
    
    assert_no_difference MovieUserCategory, :count do
      post :add_category, { :id => movies(:star_wars).id, :category => categories(:action).id }
    end
    assert_response :success

    vote = MovieUserCategory.find_by_movie_id_and_category_id(movies(:star_wars).id, categories(:action).id)
    assert vote.is_a?(MovieUserCategory)
  end
    
  # TODO fails, what's storing content in session good for ?
  #def test_edit_wiki_with_content_saved_in_session
  #  page = contents(:movie_page)
  #  movie = page.related_object
  #  text = "This is a wiki page"
  #  comment = "Changed"
  #  page.data = text
  #  get :edit, :id => movie.id, :page => page.page_name, 
  #             :content => { :data => page.data, :comment => comment }
  #  assert_success
  #  assert_tag :tag => "textarea", :content => text
  #  assert_tag :tag => "input", :attributes => { :type => "text", :value => comment }
  #  assert_nil session[:content]
  #  saved_page = Page.find(page.id)
  #  assert_not_equal text, saved_page.data
  #end
  
  
#  def test_rss_for_specific_wiki_page
#    contents(:movie_page).accept_license = '1'
#    2.times { contents(:movie_page).save! }
#    get :rss, :id => movies(:ghost).id, :page => contents(:movie_page).page_name
#    assert_equal 2, contents(:movie_page).version
#    assert_success
#    assert_tag :tag => "channel", :children => { :count => 2, :only => { :tag => "item" } }
#  end
  
#  def test_rss_for_specific_object  
#    contents(:star_wars_movie_page).accept_license = '1'
#    2.times { contents(:star_wars_movie_page).save! }
#    page = Page.create!(:data => "Star-wars rocks", :related_object => movies(:star_wars), :language => Locale.base_language, :page_name => "MyPage")
#    
#    get :rss, :id => movies(:star_wars).id
#    assert_success
#    assert_tag :tag => "channel", :children => { :count => 3, :only => { :tag => "item" } }
#  end
  
  def test_issue_261
    m = movies(:star_wars)
    get :index, :id => m.id
    assert_response :success
    xhr :post, :update_facts, :id => m.id, :movie => { :type => 'Season', :budget => '1000000', :revenue => '2000000' }
    assert_response :success
    assert_rjs :redirect, :action => 'index', :id => m.id

    get :index, :id => m.id
    assert_response :success
  end

  def test_only_admin_may_destroy
    assert_no_difference Movie, :count do
      post :destroy, :id => movies(:encounter_at_farpoint).id
    end
    assert_access_denied
  end

  # fails because of ticket #248
  #def test_destroy
  #  login_as :admin
  #  assert_difference Movie, :count, -1 do
  #    post :destroy, :id => movies(:encounter_at_farpoint).id
  #    assert_redirected_to :action => 'index'
  #  end
  #end
 
  # move the code to a better place!
  def freeze(cast)
    cast.set_frozen
    cast.save!
    cast
  end
  
end
