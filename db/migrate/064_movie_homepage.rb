class MovieHomepage < ActiveRecord::Migration
  def self.up
    add_column :movies, :homepage, :string, :limit => 100, :default => ""
    add_column :movie_versions, :homepage, :string, :limit => 100, :default => ""
  end

  def self.down
    remove_column :movies, :homepage
    remove_column :movie_versions, :homepage
  end
end
