class UserController < ApplicationController
  include AjaxController
  
  image_upload_for :user, :foto_foo => true
  movie_list_for   :user
  movie_list_for   :user, :action_name => :created, :method => :all_created_movies_paged

  before_filter :select_user, :except => [ :my_profile ]
  before_filter :login_required, :only => [ :add_movie, :delete_movie ]

  # only the user a page belongs to may modify it
  before_filter :check_user_is_owner, :only => [ :edit_page, :update_page, :create_page, :destroy_page, :new_image, :upload_image, :foto ]
  before_filter :check_my_movies, :only => [ :movies ]

  # now that our filters that should be executed before those of the
  # PageActions module are registered, we can include the PageActions
  include PageActions
  

  # weiter: page selection auch fuer index einbauen
  
  def my_profile
    if logged_in?
      redirect_to :controller => 'user', :id => current_user.permalink, :action => :index
    else
      redirect_to :controller => 'movie', :action => :index, :id => nil
    end
  end
  
  def contribs
    @log_entries = @user.log_entries.find :all, :page => { :size => 50, :current => (params[:page] || 1) }
    @log_entries.page = @log_entries.last_page if params[:page] and params[:page].to_i > @log_entries.last_page
  end
    
  def add_movie
    begin
      @movie = Movie.find( params[:movie] )
      current_user.movie_user_tags.create( :movie => Movie.find(params[:movie]), :tag => (params[:tag] || 'default') )
      flash[:add_movie] = 'successfully added to your movies'.t
    rescue
      flash[:add_movie] = 'error adding to your movies'.t
    end
    respond_to do |type|
      type.html {
        cookies[:dont_cache] = { :value => 'true', :expires => 300.seconds.from_now }
        redirect_to(request.env['HTTP_REFERER'] || { :controller => 'movie', :id => @movie.id, :action => :index })
      }
      type.js {
        render :update do |page|
          page.insert_html :bottom, 'add-movie', "<div class='small grey' id='add-movie-flash' style='display: none;'>#{flash[:add_movie]}</div>"
          page.visual_effect :fade, 'add-movie-button'
          page.visual_effect :appear, 'add-movie-flash'
        end
        flash.discard(:add_movie)
      }
    end
  end
  
  def delete_movie
    current_user.delete_tagged_movie( Movie.find(params[:movie]), (params[:tag] || 'default') )
    respond_to do |type|
      type.html { redirect_to( request.env['HTTP_REFERER'] || { :action => :movies } ) }
      type.js {
        render :update do |page|
          movies = current_user.all_movies_paged( params[:page] || 1 )
          page.visual_effect :fade, "movie_search_result_#{params[:movie]}"
          page.replace 'pagination', :partial => 'common/paginate', :locals => { :collection => movies }
        end
      }
    end
  end

  protected
   
  alias :old_find_page :find_page
  def find_page
    # 1. check, ob seite in sprache des requestenden users vorliegt
    old_find_page

    @page = nil if @page && @page.new_record?
    # 2. check, ob seite in Locale.base_language (en) vorliegt
    @page ||= @user.find_page(params[:page], Locale.base_language) ||
      # 3. check, ob seite in der sprache des anzuzeigenden benutzers vorliegt
      @user.find_page(params[:page], @user.language)             ||
      # 4. check, ob irgendeine seite vorliegt
      @user.find_page(params[:page], nil)

    @page = @page.get_version(params[:rev]) if @page.respond_to?(:get_version)
    @page ||= old_find_page # fallback to new page creation
  end

  # fulfill the PageActions contract
  def related_object; @user end
  

  # before_filter added by PageActions
  def register_tabs
    @tabs = [ 
      { :name => 'Overview'.t,  :url  => { :action => 'index' } },
      { :name => 'My Movies'.t, :url  => { :action => 'movies' } },
      { :name => 'Created Movies'.t, :url  => { :action => 'created' } },
      { :name => 'Contribs'.t,  :url  => { :action => 'contribs' } }
    ]
    @tabs << { :name => 'Pages'.t, :url  => { :action => 'page' } } if @user.has_more_pages?(@language)
  end

  def select_user
    if params[:id]
      @user = User.find_by_permalink(params[:id])
      @user ||= User.find(params[:id])
    end
    redirect_to :action => :index, :controller => 'movie' unless @user
  end

  def check_my_movies
    @my_movies = true if current_user.id == @user.id || admin?
  end

  def check_user_is_owner
    return true if current_user.id == @user.id || admin?
    flash[:error] = "You may not edit this page.".t
    access_denied
  end

end
