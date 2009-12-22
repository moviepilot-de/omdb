class AccountController < ApplicationController

  observer :user_observer

  layout :determine_layout
  
  before_filter :store_referer
  before_filter :login_required, :only => [ :picture ]
  
  def index
    render :action => 'login'
  end

  def login
    return unless request.post? && params[:login]
    self.current_user = User.authenticate(params[:login], params[:password])

    if logged_in?
      cookies.delete :logged_in
      refresh_session
      
      respond_to do |type|
        type.html { session[:login_referer].nil? ? redirect_to( :controller => 'movie', :action => 'index' ) : redirect_to( session[:login_referer] ) }
        type.js do
          render(:update) do |page| 
            page.remove 'lbContent'
            page.redirect_to session[:login_referer]
          end
        end
      end
    else
      flash.now[:error] = 'login failed'
      render(:update) do |page| 
        page.replace_html 'login_form', :partial => 'login_form'
      end if request.xhr?
    end
  end

  def signup
    @user = User.new(params[:user])
    return unless request.post?
    @user.save!
    #self.current_user = @user
    render :action => 'success'
  rescue ActiveRecord::RecordInvalid
    render :action => 'signup'
  end

  # account activation
  def activate
    redirect_to :action => 'login' && return if params[:id].nil? || params[:id].blank?
    @user = User.find_by_activation_code(params[:id])
    if @user && @user.activate
      self.current_user = @user
      redirect_back_or_default :controller => 'account', :action => 'login'
      flash[:notice] = "Your account has been activated."
    else
      redirect_to :action => 'login'
    end
  end

  # forgot password - send the user a reset-link
  def forgot_password
    return unless request.post?
    if @user = User.find_by_email(params[:email])
      @user.forgot_password
      @user.save
      flash.now[:notice] = "The password reset link has been sent to your email address."
    else
      flash.now[:notice] = "Could not find a user with that email address." 
    end
  end

  # reset the password after having received the link to this action via mail
  def reset_password
    redirect_to :action => 'login' && return if params[:id].to_s.blank?
    @user = User.find_by_password_reset_code(params[:id])
    return unless request.post? && @user

    @user.password              = params[:password]
    @user.password_confirmation = params[:password_confirmation]
    @user.reset_password
    @user.save!
    flash[:notice] = "Your password has been changed. You may now log in."
    redirect_to :action => 'login'
  rescue ActiveRecord::RecordInvalid
  end

  def picture
    data = request.raw_post
    current_user.image = Image.new if current_user.image.nil?
    @image = current_user.image
    @image.data = data
    @image.content_type = "image/png"
    @image.license = Image::LICENSE_OWNWORK
    if @image.save
      render :text => {
          :status => "ok",
          :url => url_for( @image.default_url.merge( :v => @image.version ) )
      }.to_json, :status => 200
    else
      render :nothing => true, :status => 409
    end
    
  end

  def logout
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    cookies.delete :logged_in
    flash[:notice] = "You have been logged out."
    redirect_back_or_default :controller => 'movie', :action => 'index'
    reset_session
  end
  
  private 
  
  def determine_layout
    if request.xhr?
      "ajax_box"
    else
      "account"
    end
  end
  
  def refresh_session
    if params[:remember_me] == "1"
      self.current_user.remember_me
      cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
    end
    session[:language] = current_user.language unless current_user.language.nil?
    cookies[:language] = session[:language].code
    init_cookies
  end
  
  def store_referer
    session[:login_referer] = request.env['HTTP_REFERER'] if request.env['HTTP_REFERER'] and request.env['HTTP_REFERER'] !~ /account/
  end
end
