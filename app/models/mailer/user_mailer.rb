class UserMailer < ActionMailer::Base

  def signup(user)
    setup_email(user)
    @subject    = 'Please confirm your registration with OMDB'
  end

  def welcome(user)
    setup_email(user)
    @subject    = 'Welcome to OMDB'
  end

  def forgot_password(user)
    setup_email(user)
    @subject    = 'Request to change your password'
  end


  protected
  def setup_email(user)
    @recipients  = "#{user.email}"
    @from        = 'signup@omdb.org'
    @subject     = 'OMDB'
    @sent_on     = Time.now
    @body[:user] = user
  end

end
