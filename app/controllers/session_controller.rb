# This is a temporary controller and might be removed in the future. 
class SessionController < ApplicationController

  def set_language
    @language = Language.find(params[:language]) rescue nil
    if @language
      session[:language] = @language
      cookies[:language] = @language.code
      current_user.update_attribute(:language, @language) if logged_in?
    end
    redirect_back_or_default '/'
  end

end
