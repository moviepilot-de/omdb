class VoteController < ApplicationController
  self.extend(AjaxController)

  # Don't show any layout, all vote controller actions are ajax actions.
  layout nil

  before_filter :select_vote

  # Select or create the vote the user is going to modify. If the user is anonymous,
  # we'll check if he has already voted in this session by checking th
  # session[:votes] hash. 
  # voting a 2nd time for the same movie will change the last vote and won't 
  # add a new vote to the database. 
  def select_vote
    @vote_for = params[:vote_for]
    @vote_id  = params[:id]
    session[:votes][@vote_for] = @session[:votes][@vote_for] || {}
    
    if session[:votes][@vote_for][@vote_id]
      @vote = session[:votes][@vote_for][@vote_id]
    else
      if logged_in?
        @vote = UserVote.new
        @vote.user = current_user
      else
        @vote = AnonymousVote.new
      end
      @vote.ip = request.remote_ip
    end
  end

  def vote
    render :action => 'vote_for_' + @vote_for
  end

  def register_vote
    @vote.vote = params[:vote][:vote].to_i
    # Don't allow illegal values
    if (1..10).include? @vote.vote
      @object = Module.const_get(params[:vote_for].camelize).find(params[:id])
      @vote.new_record? ? @object.votes << @vote : @vote.save
      @object.votes_count = @object.votes.size
      @object.vote = @object.median_rating
      # saving only the vote instead would result in calling the object save
      # in the update_vote method, which in turn would call the vote save method
      # so you would have basically called the vote save twice
      if @object.save
        session[:votes][@vote_for][@vote_id] = @vote
      end
    end
    redirect_to :controller => @vote_for, :action => 'refresh_overview_votes', :id => @vote_id
  end
end
