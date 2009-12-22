class MovieOfTheDay < ActiveRecord::Migration
  def self.up
    add_column :movies, :movie_of_the_day, :date
    add_column :movie_versions, :movie_of_the_day, :date
    add_index :movies, :movie_of_the_day
  end

  def self.down
    remove_index :movies, :movie_of_the_day
    remove_column :movies, :movie_of_the_day
    remove_column :movie_versions, :movie_of_the_day
  end
end
