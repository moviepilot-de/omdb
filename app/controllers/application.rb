# Ruby on Rails uses a strict MVC approach. This is the base controller, all specialised
# controllers (like MovieController or UserController) inherit from this controller.
#
# This controller is mainly used to define global filters to build a valid session, all 
# other controllers need to run.
# The filter-concept of ruby (see http://api.rubyonrails.com/classes/ActionController/Filters/ClassMethods.html) 
# helps to keep the code clean, so please implement new filters if something needs to
# be initialized for every session.
#
# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
#
# This controller also checks if an user is authorized to perform a specific action (see Actions
# for more details). 
#
# Author:: Benjamin Krause

class ApplicationController < ActionController::Base
  include AuthenticatedSystem, ExceptionNotifiable
  include LogEntryController

  # start observers
  observer :search_observer, :category_observer, :movie_observer, :image_observer

  # The layout is determined by a special method. it will basically decide,
  # whether to use a layou (normal request) or not to use (ajax requests)
  layout :determine_layout

  # dont log clear text passwords in production mode
  filter_parameter_logging 'password' if RAILS_ENV == 'production'

  # for 'remember me' functionality
  before_filter :login_from_cookie

  # Initialize the Session and build an authentication facility 
  # (see AuthenticationContext for more details).
  before_filter :init_session
  
  after_filter :set_last_modified_header
  after_filter :set_html_headers
  
  # Add a lot of usefull helpers to every controlle (see InterfaceHelper for 
  # more details)
  helper :interface
  helper :ajax
  helper :image
  helper :javascript
  helper 'wiki/wiki'
  helper :movie
  helper :log_entry
  
  protected
  
  ADDITIONAL_ARTICLES_TEXT = "Additional Articles"


  # TODO this method already exists in application_helper
  def default_url(object, view = "index")
    #url_for Util.default_url_for_object( object, view )
    url_for object.default_url( view )
  end
  

  # Set flash notice if msg parameter is given, then redirect back 
  # to the current controller's +index+ action 
  def redirect_to_index(msg = nil) #:doc: 
    flash[:notice] = msg if msg 
    redirect_to(:action => 'index') 
  end 

  # Set flash notice if msg parameter is given, then render 
  # the current controller's +index+ action 
  def render_index(msg = nil) #:doc: 
    flash[:notice] = msg if msg 
    render(:action => 'index') 
  end 


  # count popularity for every model-object, that will have a popularity index. 
  # The popularity index will help display the "most-wanted" objects of each 
  # type. The idea is based on the "most popular" lists on www.gamespot.com
  # currently the popularity is only counted, but not evaluated. to count 
  # popularities for your model, simply include an (e.g.)
  # 
  #   add_popularity @movie
  #
  # This will result in a row in the popularities table, including a timestamp, 
  # the language of the user as well as the type and id of the object. 
  # This method will only include a popularity for each object one per session.
  def add_popularity( o )
    if session[:popularities].nil?
      session[:popularities] = {}
    end
    if session[:popularities][o.class].nil? or
          session[:popularities][o.class][o.id].nil?
      p = Popularity.new
      p.for_type = o.class.to_s
      p.for_id   = o.id
      p.language = @language
      if p.save 
        session[:popularities][o.class] = {} if session[:popularities][o.class].nil?
        session[:popularities][o.class][o.id] = true
      else
      end
    end
  end

  # Fix for Safari (and perhaps other KHTML-based browsers) 
  # needing a clue about the character encoding.
  def set_html_headers
    content_type = @headers["Content-Type"] || ( request.xhr? ? 'text/javascript' : 'text/html' )
    if /^text\//.match(content_type)
      @headers["Content-Type"] = "#{content_type}; charset=utf-8" 
    end
  end
  
  def set_last_modified_header
    headers["Last-Modified"] = @last_modified.strftime('%a, %d %b %Y %H:%M:%S %Z') if @last_modified
  end

  def determine_layout
    if params[:action].to_s.eql?("rss") or params[:action].to_s.eql?("info")
      nil
    elsif request.xhr?
      "ajax_box"
    else
      "default"
    end
  end

  # Initialize the session. This basically does the following things right now:
  #
  #  * set the language that should be used for this request
  #  * initialize some necessary arrays for the views
  #
  #  These steps are necessary, regardless of the permission a user may need
  #  to perform the current action.
  def init_session
    init_language
    set_page_cache_directory
    init_views
    init_votes
    init_cookies
  end

  # Make sure we have a language set in the current request and store
  # that language in the session and initialize the Ri18n localization 
  # framework
  def init_language
    # negotiate the language with the browser if not currently set 
    # in the session
    session[:language] = negotiate_language if session[:language].nil?

    # set the language as instance var, so any controller can access
    # the language easily - this is just a shortcut :)
    @language = session[:language] || Locale.base_language

    # Initialize globalize
    Locale.set(@language.iso_639_1)
  end

  # set a few arrays that are important for each view. See register_action
  # and register_tab on how to use these arrays.
  def init_views
    @actions = @actions.nil? ? [] : @actions
    @tabs = @tabs.nil? ? [] : @tabs
  end

  # initialize votes as empty hash. this stores all votes for all type of
  # votable objects for the current session so the user may only vote once
  # per object per session. 
  # this is only needed for AnonymousVote as registered users will always
  # change their RegisteredVote
  def init_votes
    if session[:votes].nil?
      session[:votes] = Hash.new
    end
  end

  # Neccessary for apache rewrite rules  
  def init_cookies
    cookies[:language]  = @language.code                       unless cookies[:language]
    cookies[:logged_in] = (admin? ? 'admin' : logged_in?.to_s) unless cookies[:logged_in]
    cookies.delete( :dont_cache ) if cookies[:dont_cache] and flash.empty? and request.request_uri =~ /^#{cookies[:dont_cache]}/
  end

  # get the HTTP_ACCEPT_LANGUAGE header and set the language for the session 
  # accordingly. If the language of the user is not supported (see Language), 
  # it will fall back to 'en'.
  # The language of the user is only negotiated once per session and will 
  # be available to all controllers as @language. 
  def negotiate_language
    host = request.env['HTTP_X_FORWARDED_HOST'] || request.env['HTTP_HOST'] || "www.omdb.org"
    if !local_request? and host.split(":").first.split(".").first != "www"
      lang = host.split(":").first.split('.').first
    elsif request.env['HTTP_ACCEPT_LANGUAGE'].to_s.blank?
      lang = 'en'
    else
      lang = request.env['HTTP_ACCEPT_LANGUAGE'].split(',')[0]
      lang = lang.split('-')[0] if lang =~ /-/
    end
    # fall back to english if the language is currently not supported
    if not LOCALES.keys.include?( lang )
      lang = 'en'
    end
    # :TODO: This might throw a RecordNotFound Exception, but we'll
    # deal with that later on. currently its nice to see if a language
    # is not supported.
    Globalize::Language.find_by_iso_639_1(lang)
  end
  
  def set_page_cache_directory
    if params[:controller] == "image"
      self.class.page_cache_directory = "#{RAILS_ROOT}/public" # aka default-setting :)
    else
      if admin?
        self.class.page_cache_directory = "/tmp"
      else
        login_status = logged_in? ? "logged_in" : "anonymous"
        self.class.page_cache_directory = "#{RAILS_ROOT}/public/#{login_status}/#{@language.code}"
      end
    end
  end

  def extract_id(string)
    string.split('#').last
  end
  
  def select_latest_versions_for(object)
    logger.warn "select_latest_versions_for is deprecated, use object.latest_content_versions instead!"
    return object.latest_content_versions
    #column = "#{object.class.base_class.to_s.downcase}_id"
    #Content::Version.find(:all, :conditions => [ "#{column} = ?", object.id ])
    #Content::Version.find(:all, :conditions => [ "related_object_id=? AND related_object_type
  end
  
  def update_attribute( object, attribute )
    if not params[object].nil? and not params[object][attribute].nil?
      item = self.instance_variable_get("@#{object.to_s}")
      if not item.attribute_frozen?( attribute )
        normalize_date( object, attribute, params ) if item.column_for_attribute(attribute).type == :date        
        item.send( "#{attribute.to_s}=", params[object][attribute] )
      end
    end
  end
  
  # general actions common to all controllers
  
  def normalize_date( object, attribute, params )
    value = params[object][attribute]
    if value.match('\d\d\d\d-\d\d-\d\d')
      # all fine - iso format used
      return
    elsif value.size == 4
      # only year given
      params[object][attribute] = value + "-01-01"
    elsif value.match('\d\d?\.\d\d?\.\d\d$')
      # wrong format, probably something like 20.10.84
      date = value.split('.')
      year = (date[2].to_i < 10) ? date[2].to_i + 2000 : date[2].to_i + 1900
      date = Date.new( year, date[1].to_i, date[0].to_i )      
      params[object][attribute] = date.to_s
    elsif value.match('\d?\d\.\d?\d\.\d\d\d\d')
      # wrong format
      date = value.split('.')
      params[object][attribute] = date[2] + "-" + date[1] + "-" + date[0]
    else
      date = ParseDate.parsedate( value, true )
      params[object][attribute] = date[0].to_s + "-" + date[1].to_s + "-" + date[2].to_s
    end
  end

  def handle_404
    render :status => 404, :template => 'error/404'
    false
  end

  alias_method :redirect_to_without_cache_cookie, :redirect_to
  def redirect_to_with_cache_cookie(options = {}, *rest_args)
    if Hash === options && object = options.delete(:dontcache)
      cookies[:dont_cache] = { :value => url_for(object.default_url.merge( :only_path => true )), :expires => 30.seconds.from_now }
    end
    redirect_to_without_cache_cookie options, *rest_args
  end
  alias_method :redirect_to, :redirect_to_with_cache_cookie
    
end

