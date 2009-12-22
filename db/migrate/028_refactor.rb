class Refactor < ActiveRecord::Migration
  def self.up
    rename_table :genres_movies, :movie_genres
    add_column :movie_genres, :position, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :movie_genres, :position
    rename_table :movie_genres, :genres_movies
  end
end
