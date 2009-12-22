require File.dirname(__FILE__) + '/../test_helper'
require 'vote_controller'
require 'pp'

# Re-raise errors caught by the controller.
class VoteController; def rescue_action(e) raise e end; end

class VoteControllerTest < Test::Unit::TestCase
  include Arts

  fixtures :movies

  def setup
    @controller = VoteController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_vote_for_movie
    xhr :post, :vote, :vote_for => 'movie', :id => movies(:star_wars).id
    assert_success
    assert_template 'vote_for_movie.rhtml'
  end

  def test_post_vote_for_movie
    assert_equal 0, movies(:star_wars).votes_count
    assert_difference AnonymousVote, :count do
      xhr :post, :register_vote, :vote_for => 'movie', :id => movies(:star_wars).id, :vote => { :vote => 8 }
    end
    assert_redirect
    assert_redirected_to :controller => 'movie', :id => movies(:star_wars).id.to_s, :action => 'refresh_overview_votes'
    assert_equal 1, Movie.find( movies(:star_wars).id ).votes_count
    assert_equal 8, Movie.find( movies(:star_wars).id ).vote
  end
  
  def test_vote_illegal_for_movie
    assert_no_difference AnonymousVote, :count do
      xhr :post, :register_vote, :vote_for => 'movie', :id => movies(:star_wars).id, :vote => { :vote => 12 }
      xhr :post, :register_vote, :vote_for => 'movie', :id => movies(:star_wars).id, :vote => { :vote => -2 }
      xhr :post, :register_vote, :vote_for => 'movie', :id => movies(:star_wars).id, :vote => { :vote => 0 }
    end
    
    login_as :quentin
    assert_no_difference UserVote, :count do
      xhr :post, :register_vote, :vote_for => 'movie', :id => movies(:star_wars).id, :vote => { :vote => 12 }
      xhr :post, :register_vote, :vote_for => 'movie', :id => movies(:star_wars).id, :vote => { :vote => -2 }
      xhr :post, :register_vote, :vote_for => 'movie', :id => movies(:star_wars).id, :vote => { :vote => 0 }
    end
  end
end
