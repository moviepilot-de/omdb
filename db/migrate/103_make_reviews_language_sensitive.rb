class MakeReviewsLanguageSensitive < ActiveRecord::Migration
  def self.up
    add_column "reviews", "title", :string
    add_column "reviews", "language_id", :integer
  end

  def self.down

    remove_column "reviews", "title"
    remove_column "reviews", "language_id"
  end
end
