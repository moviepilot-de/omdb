class SearchController < ApplicationController
  include OMDB::Ferret
  include OMDB::Controller::SearchController

  before_filter :set_filter, :except => [ :wiki_search, :person_autocomplete, :job_autocomplete,
                                          :index, :movies, :people, :companies, :encyclopedia ]

  before_filter :new_set_filter, :only => [ :find_good_children ]
  before_filter :save_search, :only => [ :index, :movies, :people, :encyclopedia ]
  before_filter :register_tabs, :only => [ :index, :movies, :people, :encyclopedia ]

  after_filter :log_search, :only => [ :index, :movies, :people, :companies, :encyclopedia ]

  verify :method => :post, :only => [ :job_autocomplete, :person_autocomplete, :filter_languages, 
                                      :filter_countries, :find_categories, :find_people, :find_movies ]

  layout :determine_layout

  helper :movie
  helper :javascript
    
  # == Standard Searches
  # 
  # methods for the default-search
  
  # define /search/movie, /search/people and /search/encyclopedia
  [ :index, :movies, :people, :encyclopedia ].each do |term|
    define_method( term ) do
      @results = self.instance_variable_get("@#{term.to_s}_results")
      respond_to do |type|
        type.html { render :action => 'index', :layout => 'default' }
        type.js { render :template => 'common/update_search_listing', :layout => false }
        type.xml { render :action => 'xml_results', :layout => false }
      end
    end
  end
  
  def title( lang = nil )
    "Search".t
  end


  # == Special Searches 
  #
  #
  
  
  def find_people
    @movie = Movie.find(params[:movie]) if not params[:movie].nil?
    @people = Person.search_by_prefix(@filter, @language)
  end

  def find_jobs
    @job = Job.find( params[:job] ) unless params[:job].nil?
    if admin?
      @jobs = Searcher.search_job(@filter, @language.code)
    else
      @jobs = Job.search_by_prefix(@filter, @language, 0, 30)
    end
    @search_name = params[:search_name]
    if not @job.nil?
      children = @job.all_children << @job
      @jobs.delete_if { |j| children.include?(j) }
    end
  end

  def find_characters
    @allow_creation = params[:allow_creation] || false
    @cast = Cast.find(params[:cast]) unless params[:cast].blank?
    @characters = Character.search(@filter, @language)
  end

  def find_good_children
    @movie = Movie.find(params[:movie])
    @movies = Searcher.search_good_children @movie, @filter, @language.code
  end

  def find_good_parents
    @movie = Movie.find(params[:movie])
    @movies = Searcher.search_good_parents @movie, @filter, @language.code
    render :partial => 'movie', :collection => @movies
  end

  def find_companies
    if not @filter.nil? and @filter.size > 1
      @movie = Movie.find(params[:movie]) unless params[:movie].nil?
      @company = Company.find(params[:company]) unless params[:company].nil?
      @companies = Company.search_by_prefix(@filter)
      if not @company.nil?
        ids = @company.all_children.push(@company).collect{ |c| c.id }
        @companies.delete_if{ |c| ids.include?(c.id) }
      end
    else
      render :nothing => true
    end
  end

  def find_categories
    if not params[:type].nil?
      @categories = Category.search_localized_by_type( params[:type], @filter, @language )
    else
      @categories = Category.search_localized( @filter, @language )
    end
    @movie = Movie.find(params[:movie]) if not params[:movie].nil?
    @category = Category.find(params[:category]) if not params[:category].nil?
    # Top-Level Categories (like Genre) cannot be added to a movie
    if not @movie.nil?
      @categories.delete_if{ |c| c.parent_nil? }
    end
    if not @category.nil?
      ids = @category.all_children.push(@category).collect{ |c| c.id }
      @categories.delete_if{ |c| ids.include?(c.id) }
    end
    if @categories.empty?
      @categories = Category.search_localized( @filter, @language )
      render :action => 'no_livesearch_result'
    end
  end

  def find_movies
    @movie = Movie.find(params[:movie]) unless ( params[:movie].nil? or params[:movie].empty? )
    @movies = Movie.search_localized_by_prefix( @filter, @language )
    # don't find yourself
    @movies.delete_if{ |m| m.id == @movie.id } unless @movie.nil?
  end

  def find_images
    @movie = Movie.find(params[:movie]) if params[:movie]
    @images = Image.find(:all,
                         :joins => [ "left join name_aliases on name_aliases.image_id = images.id" ],
                         :conditions => [ "name_aliases.alias_type = 'Image' and name_aliases.name like ?", '%' + @filter + '%' ],
                         :select => "images.*")
    render :partial => 'image', :collection => @images
  end
  
  def filter_languages
    @languages = Language.find_localized( @filter, @language )
    if @languages.empty?
      render :action => 'no_livesearch_result'
    else
      render :partial => 'language', :collection => @languages.collect { |l| l.to_o }
    end
  end

  def filter_countries
    @countries = Country.find_localized( @filter, @language )
    if @countries.empty?
      render :action => 'no_livesearch_result'
    else
      render :partial => 'country', :collection => @countries.collect { |c| c.to_o }
    end
  end
  
  # Filter Methods
  # --------------
  #
  # The filter methods are used for all default edit-box dialogs, like the
  # add-category or add-company dialogs for movies.
  
  # :TODO: :)

  # Autocomplete Methods
  # --------------------
  #
  # The autocomplete methods are used for all drop-down-menu selections like for
  # the add-cast or movie-filter views. Each autocomplete method will return a
  # UL/LI structure.
  # 
  # @see OMDB::Controller::SearchController for implementation details
  
  autocomplete_for [ :country, :job, :category, :language ]
  autocomplete_for [ :person ], { :limit => 12, :allow_creation => true }
  autocomplete_for [ :keyword ], { :class => Category.to_s, :method => :search_keywords_by_prefix }

  def wiki_search
    @search_type = params["type"]
    @search_type ||= "movie"
  end

  private

  def log_search
    results = @results || @direct_hits
    SearchLog.create :query => session[:last_search], :results => results.size, :method => params[:action]
  end
  
  def determine_layout
    if params[:action] == "index"
      "default"
    elsif params[:action] == "wiki_search"
      "ajax_box"
    else
      nil
    end
  end

  def save_search
    if session[:last_search].nil? and (params.nil? or params[:search].nil? or params[:search][:text].nil? or params[:search][:text].empty?)
      redirect_to "/"
      return false
    else
      session[:last_search] = params[:search][:text] unless params[:search].nil?
    end
  end

  def register_tabs
    @popular_results = Searcher.search( session[:last_search], @language.code, (params[:page] || 1) )
    @index_results   = @popular_results
    @movies_results  = Searcher.search_movies( session[:last_search], @language.code, (params[:page] || 1) )
    @people_results  = Searcher.search_people( session[:last_search], @language.code, (params[:page] || 1) )
    @encyclopedia_results = Searcher.search_encyclopedia( session[:last_search], @language.code, (params[:page] || 1) )
    
    @tabs = [{ :name => "Popular Results (%d)" / @popular_results.size,
               :url  => { :action => 'index' } },
             { :name => "Movies (%d)" / @movies_results.size,
               :url => { :action => "movies"} },
             { :name => "People (%d)" / @people_results.size,
               :url => { :action => "people"} },
             { :name => "Encyclopedia (%d)" / @encyclopedia_results.size,
               :url => { :action => "encyclopedia"} }]
  end

  def set_filter
    @filter = CGI.unescape(request.raw_post).gsub(/=$/, '')
    if @filter.length < 2
      render :action => 'enter_search_term'
      return false
    end
    @wiki_search = params[:wiki_search].nil? ? false : true
    session[:filter] = @filter
  end
  
  def new_set_filter
    @filter = params['query']
    if @filter.length < 2
      render :action => 'enter_search_term'
      return false
    end
  end
  
end
