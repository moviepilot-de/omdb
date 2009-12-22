module AuthenticatedSystem
  protected
    # Returns true if the user is logged in, false otherwise.
    def logged_in?
      current_user.is_a?(User) && !current_user.anonymous?
    end
    
    # Accesses the current user from the session.
    # will load @current_user with the user model if they're logged in, and with
    # the anonymous user if not.
    def current_user
      @current_user ||= session[:user] ? User.find(session[:user]) : User.anonymous
      @current_user.ip_address = request.remote_ip
      return @current_user
    end
    
    # Store the given user in the session.
    def current_user=(new_user)
      session[:user] = (new_user.nil? || new_user.is_a?(Symbol)) ? nil : new_user.id
      @current_user = new_user
    end
    
    # Check if the user is authorized.
    #
    # Override this method in your controllers if you want to restrict access
    # to only a few actions or if you want to check if the user
    # has the correct rights.
    #
    # Example:
    #
    #  # only allow nonbobs
    #  def authorize?
    #    current_user.login != "bob"
    #  end
    def authorized?
      true
      
    end

    # Filter method to enforce a login requirement.
    #
    # To require logins for all actions, use this in your controllers:
    #
    #   before_filter :login_required
    #
    # To require logins for specific actions, use this in your controllers:
    #
    #   before_filter :login_required, :only => [ :edit, :update ]
    #
    # To skip this in a subclassed controller:
    #
    #   skip_before_filter :login_required
    #
    def login_required
      username, passwd = get_auth_data
      if username && passwd
        self.current_user ||= User.authenticate(username, passwd) || User.anonymous 
      end
      logged_in? && authorized? ? true : access_denied
    end
    
    def admin_required
      return false unless login_required # access_denied has already been called in this case
      return true if admin? 
      access_denied # redirect to login in case user is logged in, but no admin
    end

    def editor_required
      return false unless login_required
      return true if editor? 
      access_denied
    end
    
    # Redirect as appropriate when an access request fails.
    #
    # The default action is to redirect to the login screen.
    #
    # Override this method in your controllers if you want to have special
    # behavior in case the user is not authorized
    # to access the requested action.  For example, a popup window might
    # simply close itself.
    def access_denied
      store_location
      respond_to do |accepts|
        accepts.html do
          redirect_to :controller => '/account', :action => 'login'
        end
        accepts.js do
          render :update do |page|
            page.redirect_to :controller => '/account', :action => 'login'
          end
        end
        accepts.xml do
          headers["Status"]           = "Unauthorized"
          headers["WWW-Authenticate"] = %(Basic realm="Web Password")
          render :text => "Could't authenticate you", :status => '401 Unauthorized'
        end
      end
      false
    end  
    
    # Store the URI of the current request in the session.
    # Called as a before_filter, will store the uri only if the 
    # request is not Ajax and no POST.
    # We can return to this location by calling #redirect_back_or_default.
    def store_location
      respond_to do |accepts|
        accepts.html do
          session[:return_to] = request.request_uri if request.get? && !request.xhr?
        end
      end
    end
    
    # Reload the current page (in case of ajax requests) or redirects to the HTTP_REFERRER, 
    # and if none given, to default.
    def redirect_back_or_default(default)
      if session[:return_to]
        if request.xhr?
          render(:update) { |page| page.redirect_to session[:return_to] }
        else
          redirect_to session[:return_to]
        end
        session[:return_to] = nil
      else
        if request.xhr?
          render(:update) { |page| page << 'window.location.reload();' }
        else
          redirect_to :back
        end
      end
    rescue ActionController::RedirectBackError # raised if no HTTP_REFERER present in request
      redirect_to default
    end

    # true if current user is admin
    def admin?
      current_user.is_admin?
    end

    # true if current user is editor
    def editor?
      current_user.is_editor?
    end

    
    # Inclusion hook to make #current_user and #logged_in?
    # available as ActionView helper methods.
    def self.included(base)
      base.send :helper_method, :current_user, :logged_in?, :admin?, :editor?
    end

    # When called with before_filter :login_from_cookie will check for an :auth_token
    # cookie and log the user back in if apropriate
    def login_from_cookie
      return unless cookies[:auth_token] && !logged_in?
      user = User.find_by_remember_token(cookies[:auth_token])
      if user && user.remember_token?
        user.remember_me
        self.current_user = user
        session[:language] = user.language if user.language
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
        flash[:notice] = "Logged in successfully"
      end
    end

  private
    # gets BASIC auth info
    def get_auth_data
      user, pass = nil, nil
      # extract authorisation credentials 
      if request.env.has_key? 'X-HTTP_AUTHORIZATION' 
        # try to get it where mod_rewrite might have put it 
        authdata = request.env['X-HTTP_AUTHORIZATION'].to_s.split 
      elsif request.env.has_key? 'HTTP_AUTHORIZATION' 
        # this is the regular location 
        authdata = request.env['HTTP_AUTHORIZATION'].to_s.split  
      end 
       
      # at the moment we only support basic authentication 
      if authdata && authdata[0] == 'Basic' 
        user, pass = Base64.decode64(authdata[1]).split(':')[0..1] 
      end 
      return [user, pass] 
    end
end
