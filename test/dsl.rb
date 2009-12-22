class ActionController::IntegrationTest

  module OmdbDSL

    def goto_movie(movie = Movie.find(:first))
      get "/movie/#{movie.id}"
      assert_response :success
    end
    
    def goto_person(person = Person.find(:first))
      get "/person/#{person.id}"
      assert_response :success
    end

    def goto_category(cat = Category.find(:first))
      get "/encyclopedia/category/#{cat.id}"
      assert_response :success
    end

    def login_with(args)
      post "/account/login", args
      follow_redirect!
    end

    def logout
      get '/account/logout'
      follow_redirect!
    end

    # Seacrch specific methods
    def search_for( query )
      post '/search/index', :search => { :text => query }
      assert_equal query, session[:last_search]
      assert_response :success
    end

    def goto_search_tab_movies
      get url_for( :controller => 'search', :action => :movies )
      assert_response :success
    end

    def goto_search_tab_people
      get url_for( :controller => 'search', :action => :people )
      assert_response :success
    end

    def goto_search_tab_companies
      get url_for( :controller => 'search', :action => :companies )
      assert_response :success
    end

    def goto_search_tab_encyclopedia
      get url_for( :controller => 'search', :action => :encyclopedia )
      assert_response :success
    end

  end

  def new_session_as(user, pass='test')
    user = users(user) unless User === user
    new_session do |sess|
      sess.login_with(:login => user.login, :password => pass)
      yield sess if block_given?
    end
  end

  def new_session
    open_session do |sess|
      sess.extend(OmdbDSL)
      sess.extend(MultipartPost)
      yield sess if block_given?
    end
  end
end
