class MovieCreatedAt < ActiveRecord::Migration
  def self.up
    add_column :movies, :created_at, :datetime
    add_column :movie_versions, :created_at, :datetime
  end

  def self.down
    remove_column :movies, :created_at
    remove_column :movie_versions, :created_at
  end
end
