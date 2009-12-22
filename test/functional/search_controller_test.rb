require File.dirname(__FILE__) + '/../test_helper'
require 'search_controller'

# Re-raise errors caught by the controller.
class SearchController; def rescue_action(e) raise e end; end

class SearchControllerTest < Test::Unit::TestCase
  include TestOmdbHelper
  include OMDB::Test::Controller::SearchControllerTestHelper

  fixtures :movies, :globalize_countries, :images, :people, :name_aliases, 
           :categories, :movie_user_categories, :jobs, :characters

  set_fixture_class(:globalize_countries=> "Country")
  

  def setup
    @controller = SearchController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    Searcher.reload!
  end
  
  def teardown
    Searcher.close!
  end

  # Test the autocomplete-methods
  # -----------------------------
  # see OMDB::Test::Controller::SearchControllerTestHelper for more details.
  
  autocomplete_test_for :person, :peter_jackson, 'pe ja'
  autocomplete_test_for :person, :jack_peterson, 'ja pe' do |instance|
    instance.assert_no_tag( :li, :content => "Peter Jackson" )
  end
  
  autocomplete_test_for :category, :action, 'act'
  autocomplete_test_for :job, :director, 'dir'
  autocomplete_test_for :country, :usa, 'unit', :fetch_method => 'globalize_countries'
  
  def test_keyword_autocomplete
    xhr :post, :keyword_autocomplete, :keyword => 'York'
    assert_response :success
    assert_tag :li, :content => "New York"
  end

  def test_job_autocomplete_multiple_terms
    xhr :post, :job_autocomplete, :job => 'exec prod'
    assert_response :success
    assert_tag :li, :content => 'Executive Producer'
  end

  def test_person_autocomplete_get_request
    get :person_autocomplete
    assert_response 0
  end


  def test_search
    assert_difference SearchLog, :count do
      post :index, :search => { :text => "trek" }
      assert_success
      assert_tag :tag => "a", :content => "Star Trek - The Movie", :attributes => { :href => %r{/movie/289} }
    end
  end

  def test_search_index_xml
    accept 'application/xml'
    post :index, :search => { :text => "naomi watts" }
    assert_response :success
    assert_match @response.headers['Content-Type'], "application/xml"
    assert_template 'xml_results.rxml'
    assert_tag :tag => "name", :content => "Naomi Watts"
    assert_tag :tag => "name", :content => "King Kong"
  end
  
  def test_search_movies_xml
    accept 'application/xml'
    post :movies, :search => { :text => "star" }
    assert_response :success
    assert_match @response.headers['Content-Type'], "application/xml"
    assert_template 'xml_results.rxml'
    assert_tag :tag => "name", :content => "Star Wars"
  end

  def test_search_people_xml
    accept 'application/xml'
    post :people, :search => { :text => "george" }
    assert_response :success
    assert_match @response.headers['Content-Type'], "application/xml"
    assert_template 'xml_results.rxml'
    assert_tag :tag => "name", :content => "George Keller"
  end

  def test_find_person
    post :index, :search => { :text => "Naomi Watt" }
    assert_success
    assert_tag :tag => "a", :content => "Naomi Watts", :attributes => { :href => %r{/person/3489} }
  end
  
  
#  def test_job_autocomplete_german
#    # Franz spricht deutsch :-)
#    login_as :franz
#    xhr :post, :job_autocomplete, :job => 'direc'
#    assert_response :success
#    assert_tag :li, :content => "Regisseur", :child => { :tag => :span, :content => "Director"}    
#  end
    
  # The index page will only display movies, people and characters. No categories, companies
  # or the like
  def test_find_category
    action = categories(:action)
    post :index, :search => { :text => "Actio" }
    assert_success
    assert_no_tag :tag => "a", :content => action.name, :attributes => { :href => %r{/category/28} }
  end
    
  # if a search query finds exactly one hit, we'll redirect to this hit.
  # DIRECT HIT DISABLED <bk> 20070407
  # def test_find_direct_hit
  #  post :index, :search => { :text => "Tim Burton" }
  #  assert_redirect 
  #  assert_equal "http://test.host/person/510", @response.redirected_to
  #end
  
  # This threw a lot of 'invalid query' exceptions in the past
  def test_search_with_stop_word
    post :index, :search => { :text => 'the' }
    assert_success
  end

  # find categories for two-colum-list-select boxes
  def test_find_categories
    @request.env["RAW_POST_DATA"] = "act"
    xhr :post, :find_categories, :type => 1, :name => 'genre'
    assert_success
    assert @response.body.include?('add_genre(\'' + categories(:action).id.to_s + '\');')
  end
  
  def test_find_other_categories
    @request.env["RAW_POST_DATA"] = 'Holly'
    xhr :post, :find_categories, :type => "1", :name => 'genre'
    assert_success
    assert_tag :a, :content => 'Production'
  end

  def test_find_categories_production
    @request.env["RAW_POST_DATA"] = "hol"
    xhr :post, :find_categories, :type => 7, :name => 'production'
    assert_success
    assert @response.body.include?('add_production(\'' + categories(:hollywood).id.to_s + '\');')
  end
  
  def test_find_characters
    indy = characters(:indiana_jones)
    @request.env["RAW_POST_DATA"] = "ind"
    xhr :post, :find_characters
    assert_response :success
    assert_tag :a, :content => indy.name
  end
  
  def test_wiki_search
    xhr :get, :wiki_search
    #added this line, should something else be tested too?
    assert_response :success
  end

  def test_find_good_children
    xhr :post, :find_good_children, { :movie => movies(:batman_series).id, :query => 'willy' }
    assert_response :success
    assert_tag :a, :content => movies(:willy_wonka).name
  end
  
  #some other error, is this used anyome?
  #def test_find_images
  #  @request.env["RAW_POST_DATA"] = "bild"
  #  xhr :post, :find_images, :movie => movies(:star_wars).id
  #  assert_success
  #  assert_equal 1, assigns(:images).size
  #  assert_equal images(:image).id, assigns(:images).first.id
  #end
  
  def test_find_people
    @request.env["RAW_POST_DATA"] = "naomi"
    xhr :post, :find_people, :movie => movies(:king_kong).id
    assert_success
    #was assert_equal 2 but there's only one naomie in this movie, at least there's only one naomie in the people fixtures...
    assert_equal 1, assigns(:people).size
  end
  
  def test_find_movies
    @request.env["RAW_POST_DATA"] = "star"
    xhr :post, :find_movies, :movie => movies(:cat_on_a_hot_tin_roof).id
    assert_success
    assert_equal 3, assigns(:movies).size
    assert_tag :li, :content => movies(:star_wars).name
    # We cannot assure the order anymore .. 
    # assert_equal movies(:star_wars).id, assigns(:movies).first.id
  end

  # :TODO: Bug, this should find the USA, but it doesn't.. If you just
  # search for "United States", everything is fine.. 
  def test_filter_countries
    @request.env["RAW_POST_DATA"] = "United States of America"
    xhr :post, :filter_countries
    assert_success
    assert_equal 1, assigns(:countries).size    
    assert_equal Country.find_by_code('US').id, assigns(:countries).first.id
  end

  def test_filter_countries_2
    @request.env["RAW_POST_DATA"] = "ita"
    xhr :post, :filter_countries
    assert_success
    assert_equal 1, assigns(:countries).size    
    assert_equal Country.find_by_code('IT').id, assigns(:countries).first.id
  end

  def test_filter_languages
    @request.env["RAW_POST_DATA"] = "engl"
    xhr :post, :filter_languages
    assert_success
    assert_equal 1, assigns(:languages).size
    assert_equal Language.find_by_iso_639_1('en').id, assigns(:languages).first.id
  end

  def test_filter_non_existing_languages
    @request.env["RAW_POST_DATA"] = "xzy"
    xhr :post, :filter_languages
    assert_success
    assert_template 'no_livesearch_result.rhtml'
  end

  def test_search_with_empty_search
    get :index
    assert_redirected_to "/"
  end


end
