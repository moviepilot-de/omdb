class UserObserver < ActiveRecord::Observer
  def after_create(user)
    UserMailer.deliver_signup(user) if user.send_signup_mail?
  end

  def after_save(user)
    UserMailer.deliver_welcome(user) if user.recently_activated?
    UserMailer.deliver_forgot_password(user) if user.recently_forgot_password?
  end
  
  def after_destroy(user)
    #remove user category votes
    votes = MovieUserCategory.find_user_votes(user)
    #delete all the votes of the user, the before/after destroy hooks should take care of the rest 
    votes.each do |v|
      #delete the vote
      v.destroy
    end if votes
  end
end
