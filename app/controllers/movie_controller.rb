      # MovieController
#
# Main Controller for Movie-Actions. 
#
# See also: CastController
#
# Author:: Benjamin Krause <bk@benjaminkrause.com>

class MovieController < ApplicationController
  include OMDB::Controller::ChangesController
  include AjaxController
# include TrackBackController
  include Akismet

  cache_sweeper :generic_log_observer
  cache_sweeper :movie_user_category_log_observer
  cache_sweeper :production_company_log_observer
  cache_sweeper :cast_log_observer

  verify :method => :post, :only => [ :set_abstract, :destroy ]
  verify :xhr => true, :only => [ :set_abstract, :display_category_vote_icons, :display_keyword_vote_icons,
                                  :display_categories, :display_keywords ]


  # class extensions (/movie/changelog)  
  changes_page_for :movie

  # instance extensions (e.g. /movie/<id>/set_abstract)
  set_abstract_for :movie
  edit_aliases_for :movie
  image_upload_for :movie
  history_view_for :movie

  before_filter :select_movie, :except => [ :create, :list, :status, :random ]
  before_filter :login_required, :only => [ :display_category_vote_icons, :display_keyword_vote_icons, :destroy_alias, :new_image, :upload_image ]
  before_filter :admin_required, :only => [ :destroy ]

  refresh_action :movie, :overview_votes

  lightbox_edit_for :movie, :edit_status, :update_edit_status
  
  help_view [ :facts, :categories, :references, :aliases, :keywords ]

  helper :cast, :user
  
  caches_page :index, :cast, :parts, :histroy, :embed_data

  # Need to include PageActions after all other filters have been set.
  include PageActions

  #
  # Basic views (tabs)
  #
  
  def cast
  end
  
  def embed
    render :template => 'movie/embed', :layout => 'plain'
  end
  
  def embed_data
    render :template => 'movie/embed_data', :layout => false
  end
  
  def reviews
    @pages, @reviews = paginate :review,
      :per_page => 5, :conditions => [ "related_object_id = ? and related_object_type = ?", @movie.id, 'Movie' ]
  end

  def statistics
    @object = @movie
    render 'common/statistics'
  end

  ### CRUD methods

  def new
    respond_to do |type|
      type.html { redirect_to :action => :index }
      type.js { new_movie_wizard }
    end
  end
  
  def create
    respond_to do |type|
      type.js { create_via_wizard }
    end
  end
  
  def destroy
    respond_to do |type|
      type.html {
        Movie.find(params[:id]).destroy
        redirect_to :action => :index, :id => nil
      }
    end
  end


  ### Other public methods
  
  def latest
    @movies = Movie.recently_added(:limit => 20, :include => :creator)
    render :layout => false, :action => "latest_#{params[:type]}" if params[:type] =~ /^rss$/
  end
  
  def search_box
    render :partial => 'search_box', :locals => { :search_box => @movie }
  end
  
  def random
    @movie = Movie.random_movie
    redirect_to :action => :index, :id => @movie.id
  end
  
  # Find all movies of a certain status
  def status
    @movies = Movie.find(:all, :conditions => [ "edit_status = ?", params[:status] ])
    @movie_pages = Paginator.new self, @movies.size, 25, params[:page]
    @movies = @movies.slice(@movie_pages.current.offset, 25)
  end
  
  def top
    @movies = Movie.top_100_movies
  end
  
  def bottom
    @movies = Movie.bottom_100_movies
    render :action => :top
  end
  

  ### AJAX Update Actions
  
  def update_facts
    update_attribute :movie, :name
    update_attribute :movie, :status
    update_attribute :movie, :homepage
    update_attribute :movie, :end
    update_attribute :movie, :runtime
    update_attribute :movie, :budget
    update_attribute :movie, :revenue
    update_attribute :movie, :inherit_cast
    update_attribute :movie, :series_type if @movie.is_a? Series
    update_languages unless @movie.attribute_frozen? :languages
    update_countries unless @movie.attribute_frozen? :countries
    update_companies unless @movie.attribute_frozen? :production_companies
    update_trailers 
    update_alias unless params[:select_alias].nil?

    # redirect and return if the movie class has been changed (which will not happen that often)
    if change_movie_class and @movie.save
      render :update do |page|
        page.redirect_to :action => :index
      end
      return
    end
        
    if not @movie.save
      render :action => 'edit_facts'
    end
    @movie.reload
  end


  ### Other AJAX Actions .. 

  def create_reference
    respond_to do |type|
      type.js   { create_reference_js }
      type.html { redirect_to :action => :index }
    end
  end
 
  def stub
    respond_to do |type|
      type.js   { render :partial => 'movie_stub', :layout => false }
      type.html { redirect_to :action => :index }
    end
  end
  
  def display_category_vote_icons
    @vote_icons = true
    render(:update) do |page|
      page.replace_html 'overview-category-votes', :partial => 'overview_categories'
      page.visual_effect :blind_up, 'overview-categories'
      page.visual_effect :slide_down, 'overview-category-votes'
    end
  end
  
  def display_categories
    render(:update) do |page|
      page.replace_html 'overview-categories', :partial => 'overview_categories'
      page.visual_effect :blind_up, 'overview-category-votes'
      page.visual_effect :slide_down, 'overview-categories'
    end
  end

  def display_keyword_vote_icons
    @vote_icons = true
    render(:update) do |page|
      page.replace_html 'overview-keyword-votes', :partial => 'overview_keywords_vote'
      page.visual_effect :blind_up, 'overview-keywords'
      page.visual_effect :slide_down, 'overview-keyword-votes'
    end
  end
  
  def display_keywords
    render(:update) do |page|
      page.replace_html 'overview-keywords', :partial => 'overview_plot_keywords'
      page.visual_effect :blind_up, 'overview-keyword-votes'
      page.visual_effect :slide_down, 'overview-keywords'
    end
  end


  def delete_reference
    begin
      @reference = Reference.find(params[:reference])
      @reference.destroy
      @movie.reload
    rescue ActiveRecord::RecordNotFound
      # Reference gone?
    end
    render(:update) { |page|
      page.replace_html 'overview-references', :partial => 'overview_references'
    }
  end
  
  def add_new_keyword
    new_cat = Category.new( :parent => Category.default_keyword_parent )
    name = request.raw_post
    new_cat.aliases << NameAlias.new( :related_object => new_cat, :name => name, :language => @language )
    new_cat.aliases << NameAlias.new( :related_object => new_cat, :name => name, :language => Locale.base_language ) unless @language.id == Locale.base_language.id
    new_cat.save
    
    add_category new_cat.id
  end

  def add_category( category_id = params[:category], rendering = true )
    begin
      category = Category.find(category_id)
      MovieUserCategory.register_user_vote_for_movie_category( current_user, @movie, category, 1 )

      if rendering
        render :update do |page|
          if params[:create]
            page.replace_html "overview-keywords", :partial => 'overview_plot_keywords'
          else
            page.replace "movie_category_#{category.id}", :partial => "category", :object => category unless category.root.id == Category.plot_keyword.id
            @vote_icons = true
            page.replace "movie_category_#{category.id}_vote", :partial => "category", :object => category
          end
        end
      end    
    rescue ActiveRecord::RecordNotFound
      render :inline => "Already destroyed".t, :status => 404
    end
  end

  def delete_category( category_id = params[:category], rendering = true )
    category = Category.find(category_id)
    MovieUserCategory.register_user_vote_for_movie_category( current_user, @movie, category, -1 )
    
    if rendering
      render :update do |page|
        if category.count_for_movie( @movie ) < 1
          page.visual_effect :fade, "movie_category_#{category.id}" unless category.root.id == Category.plot_keyword.id
          page.visual_effect :fade, "movie_category_#{category.id}_vote"
        else
          page.replace "movie_category_#{category.id}", :partial => "category", :object => category unless category.root.id == Category.plot_keyword.id
          @vote_icons = true
          page.replace "movie_category_#{category.id}_vote", :partial => "category", :object => category
        end
        
      end
    end
  end
  
  def new_review
  #wiki_action @movie
    # if request.xhr?
      if logged_in?
        user = current_user
        @review = @movie.reviews.find_by_user_id user.id
        @vote = @movie.votes.find_by_user_id user.id
        if @review.nil?
          @review = Review.new(:data => "")
        end
      else
        flash[:error] = "This feature is only available for logged-in users."
      end
    # else
    #   render :nothing => true
    # end
    render :update do |page|
      page.replace_html "add_review", :partial => "new_review"
      page.show "add_review"
    end
  end
  
  def create_review
    if request.xhr?
      if logged_in?
        user = current_user
        @review = @movie.reviews.find_by_user_id user.id
        @vote = @movie.votes.find_by_user_id user.id
        if @review.nil?
          @review = Review.create(:page_name => params[:review][:page_name].blank? ? params[:review][:data].first(10) + "..." : params[:review][:page_name],
                                  :data => params[:review][:data],
                                  :user => user,
                                  :related_object => @movie,
                                  :language_id => @language.id)
          if @vote.nil? && params[:vote]
            @vote = UserVote.create(:user => user,
                                    :movie => @movie,
                                    :ip => request.remote_ip, 
                                    :vote => params[:vote][:vote])
          end
        else
          @review.update_attributes(params[:review])
          @vote.update_attributes(params[:vote])
        end
        @movie.votes.reload
        @movie.votes_count = @movie.votes.size
        @movie.reviews.reload
        @movie.reviews_count = @movie.reviews.size
        @movie.save!
      else
        flash[:error] = "This feature is only available for logged-in users."
      end
    end
  end
  
  def assign_child
    if not params[:movie].nil?
      @other_movie = Movie.find(params[:movie])
      @other_movie.parent = @movie
      @other_movie.save
    end
    render :action => 'update_children'
  end

  def assign_parent
    if not params[:movie].nil?
      @other_movie = Movie.find(params[:movie])
      @movie.parent = @other_movie
      @movie.save
    end
    render :action => 'update_facts', :locals => { :close_box => true }
  end

  def update_children
    update_children_of_movie
    render(:update) do |page|
      page << 'box.deactivate();'
      page.replace_html 'movie-children', :partial => 'child',
                                          :collection => @movie.children[0..2]
      page.call 'updateStub', url_for( :action => :stub )
    end
  end
  
  def update_categories
    update_movie_categories 
    create_new_categories
    render(:update) do |page|
      @categories = Category.categories_for_movie @movie
      page.replace_html 'overview-categories', :partial => "overview_categories"
      page << 'box.deactivate();'
      page.call 'updateStub', url_for( :action => :stub )
    end
  end

  def sort_department
    @department = Department.find( params[:department] )
    param  = "movie-" + @department.id.to_s
    if not params[param].nil?
      Cast.employees( @movie, @department ).each { |c|
        if params[param].include?(c.id.to_s)
          c.position = params[param].index(c.id.to_s) + 1
          c.save
        end
      }
    end
    render :nothing => true
  end
  
  ###
  ### Private Methods
  ###
  
  private 

  ### Production Companies
  
  # Add and delete ProductionCompany-Relations, create new companies if neccessary
  def update_companies
    current_companies = @movie.companies.collect { |c| c.id.to_s }

    delete_production_companies( current_companies )
    add_production_companies( current_companies ) unless params[:companies].nil?
    create_new_companies unless params[:new_companies].nil?
  end

  # Add new ProductionCompany-Relations to a movie, as requested by update-facts
  def add_production_companies( current_companies )
    # Create new Production Companies
    params[:companies].each do |id|
      unless current_companies.include?( id )
        @movie.production_companies << ProductionCompany.new( :company_id => id.to_i )
      end
    end
  end

  # Delete Production Companies that are not part of the update-facts request.
  def delete_production_companies( current_companies )
    if params[:companies].nil?
      @movie.production_companies = []
    else
      current_companies.each do |id|
        unless params[:companies].include?( id )
          @movie.production_companies.each { |pc| pc.destroy if pc.company.id == id.to_i }
        end
      end
    end
  end
  
  # Create new companies as requested by update-facts
  def create_new_companies
    params[:new_companies].each do |name|
      c = Company.new
      c.name = CGI.unescape(name)
      c.save
      @movie.production_companies << ProductionCompany.new( :company => c )
    end
  end


  ### Movie-Languages
  
  def update_languages
    if params[:languages].nil? or params[:languages].empty?
      @movie.languages = []
    else
      @movie.language_ids = params[:languages]
    end
  end

  ### Movie-Countries

  def update_countries
    if params[:countries].nil? or params[:countries].empty?
      @movie.countries = []
    else
      @movie.country_ids = params[:countries]
    end
  end
  
  
  ### Trailers
  
  def update_trailers
    if params[:trailer] and params[:trailer][:key]
      @movie.trailer(@language).key = params[:trailer][:key]
    end
  end
  
  def update_alias
    case params[:select_alias]
      when '0'
        @movie.no_official_translation( @language )
      when 'new'
        unless params[:new_alias].nil? or params[:new_alias].empty?
          @movie.no_official_translation( @language )
          @movie.aliases.create :language => @language, :name => params[:new_alias], :official_translation => true
        end
      else
        new_official = NameAlias.find( params[:select_alias] )
        if @movie.official_translation(@language).empty? or new_official.id != @movie.official_translation(@language).first.id
          @movie.no_official_translation( @language )
          new_official.official_translation = true
          new_official.save
        end
    end
  end
  
  ### Movie-References
  
  def create_reference_js
    if params[:reference].nil?
      render(:update) do |page|
        page.replace_html 'new-reference-wizard', :partial => 'new_reference_page_2'
      end
    else
      create_new_reference
      render(:update) { |page|
        page << 'box.deactivate();'
        page.replace_html 'overview-references', :partial => 'overview_references'
      }
    end
  end

  def create_new_reference
    if not @movie.attribute_frozen?( :references )
      @reference = Module.const_get(params[:reference][:class].camelize).new
      @reference.movie = @movie
      @reference.referenced_movie = Movie.find(params[:reference][:movie])
      @reference.save!
    end
  end

  def update_children_of_movie
    params[:movies] ||= []
    movies = params[:movies].uniq
    # remove children
    @movie.children.each { |m|
      if not m.attribute_frozen?( :parent )
        if not params[:movies].include?( m.id.to_s )
          m.parent = nil
          m.save!
        end
      end
      movies.delete( m.id.to_s )
    }
    # add children
    movies.each { |m|
      movie = Movie.find(m)
      if not movie.attribute_frozen?( :parent )
        movie.parent = @movie
        movie.save!
      end
    }
    @movie.reload
  end

  def update_movie_categories
    categories = []
    [ 'categories', 'genres', 'productions', 'audiences', 'standings', 'types', 
      'sources', 'formats', 'epoches', 'terms' ].each { |param|
      categories << params[param] unless params[param].nil?
    }
    categories.flatten!

    # remove categories - only admins are allowed to remove categories, all other
    # users have to vote.
    if admin?
      @movie.categories.each do |c|
        delete_category(c.id, false) unless categories.include?( c.id.to_s )
        categories.delete( c.id.to_s )
      end
    end

    # add categories
    categories.each { |c|
      add_category( c, false )
    }
  end

  def update_movie_keywords
    keywords = [] 
    keywords << params[:categories] unless params[:categories].nil? 
    keywords << params[:plot_keywords] unless params[:plot_keywords].nil?
    keywords.flatten!

    @movie.plot_keywords.each { |k|
      @movie.delete_category k unless keywords.include?( k.id.to_s )
    }
    params[:plot_keywords].each { |id|
      keyword = Category.find id
      MovieUserCategory.new( :movie => @movie, :category => keyword, :user => User.anonymous ).save
    } unless params[:plot_keywords].nil?
    @movie.reload
  end

  def create_new_categories
    { 'new_genres'     => 'genre',    'new_productions' => 'production', 
      'new_audiences'  => 'audience', 'new_standings'   => 'standing',
      'new_types'      => 'types',    'new_sources'     => 'source', 
      'new_epoches'    => 'epoch', 
      'new_terms'      => 'term' }.each { |param, type|
        params[param].each { |name|
          new_cat = Category.new( :parent => Category.send(type) )
          new_cat.aliases << NameAlias.new( :related_object => new_cat, :name => name, :language => @language )
          new_cat.aliases << NameAlias.new( :related_object => new_cat, :name => name, :language => Locale.base_language ) unless @language.id == Locale.base_language.id
          new_cat.save
          add_category( new_cat.id, false )
        } unless params[param].nil?
    }
  end

  def change_movie_class
    if params[:movie] and params[:movie][:type] and not params[:movie][:type].empty?
      if Movie.valid_types.include?( params[:movie][:type].constantize ) and not
        @movie.attribute_frozen?(:type) and not @movie.class == params[:movie][:type].constantize
        @movie.update_attribute(:type, params[:movie][:type] )
        # mal gucken ob's auch ohne geht
        # Indexer.index_object @movie
        return true
      end
    end
    false
  end
  

  ### New Movie Wizard

  def new_movie_wizard
    if not @movie.nil? and ( not @movie.parent.nil? or [ MovieSeries, Series ].include?(@movie.class) ) and params[:movie].nil?
      render :action => 'new_select_type'
    else
      select_movie_for_creation
      new_movie_wizard_input
    end
  end

  def new_movie_wizard_input
    if params[:movie].nil? or params[:movie][:name].nil? or params[:movie][:name].empty?
      # Enter the name of the Movie
      render :action => 'new'
    else
      # Search for other movies of this name
      @movies = Movie.search_localized( params[:movie][:name], @language )
      @original_name_unknown = true if params[:original_name_unknown] == "on"
      
      # If there're no other movies of the same name, continue with the creation
      # else display an option list of already existing movies.
      # The user can decide to create anyway, if he checks the 'continue' checkbox.
      if @movies.empty? || params[:continue] == 'on'
        create
      else
        # Display all movies that matches the newly entered movie name
        render :action => 'new_page2'
      end
    end
  end
  
  def create_via_wizard
    select_movie_for_creation
    
    if @movie.save
      create_alias_via_wizard if not params[:original_name_unknown].nil?
      render :action => 'thank_you', :layout => false
    else
      render(:update) do |page|
        page.replace_html 'new_movie_content', :partial => 'new_error'
      end
    end
  end
  
  def create_alias_via_wizard
    a = NameAlias.new( :name => @movie.name, :official_translation => true )
    a.related_object = @movie
    a.language = @language
    a.official_translation = true
    a.save
  end
  

  ### Filters

  def select_movie
    if params[:id]
      params[:id] = params[:id].split('_').last if params[:id] =~ /_/
      @movie  = Movie.find(params[:id])
      @trailer = @movie.trailer(@language) if @movie.class.has_trailers?
      @last_modified = @movie.log_entries.first.created_at unless @movie.nil? or @movie.log_entries.empty?
    end
  end
  
  def select_movie_for_creation
    @movie = params[:movie].nil? ? Movie.new : params[:movie][:class].constantize.new
    @movie.creator = current_user
    @movie.parent = Movie.find( params[:parent_movie] ) unless params[:parent_movie].nil?
    @movie.name = params[:movie][:name] unless params[:movie].nil? or params[:movie][:name].nil?
  end
  
  def related_object; @movie end

  def register_tabs
    if not @movie
      # Tabs for the movie portal page
      @tabs = [
        { :name => "Movies".t, :url => { :action => 'index' } },
        { :name => "Top 100".t, :url => { :action => 'top' } },
        { :name => "Bottom 100".t, :url => { :action => 'bottom' } }
        ]
      @tabs << { :name => "Changes".t, :url  => { :action => 'changes' } } if admin?
    else
      # Tabs for a movie
      @tabs = [
        { :name => "Overview".t, :url  => { :action => 'index' } }
      ]
      @tabs << { :name => "Parts".t, 
                 :url  => { :action => 'parts' } } if MovieSeries === @movie
                                                     # [ MovieSeries, 
                                                     #   Series, 
                                                     #   Season ].include?(@movie.class)

      @tabs << { :name => "Crew / Cast".t,
                 :url  => { :action => 'cast' } } if @movie.class.has_cast?
      @tabs << { :name => ADDITIONAL_ARTICLES_TEXT.t,
                 :url  => { :action => 'page' } } if @movie.has_more_pages?(@language)
      @tabs << { :name => "History".t,
                 :url  => { :action => 'history' } }
      # @tabs << { :name => "Reviews".t + (@movie.reviews_count > 0 ? " (#{@movie.reviews_count})" : ''),
      #            :url  => { :action => 'reviews' } } if @movie.class.has_reviews? && @movie.status == "Released"
      @tabs << { :name => 'Statistics'.t,
                 :url  => { :action => 'statistics' } } if @movie.class.has_statistics? 
    end
  end
  

end
