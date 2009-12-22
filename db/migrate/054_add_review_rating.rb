class AddReviewRating < ActiveRecord::Migration
  def self.up
    add_column :reviews, :rating, :integer
  end

  def self.down
    remove_column :reviews, :rating
  end
end
