class AddVoteAndReviewCounters < ActiveRecord::Migration
  def self.up
    add_column "movies", "votes_count", :integer, :default => 0
    add_column "movies", "reviews_count", :integer, :default => 0
  end

  def self.down
    remove_column "movies", "vote_count"
    remove_column "movies", "review_count"
  end
end
