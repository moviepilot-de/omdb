class AddMovieLanguagesPosition < ActiveRecord::Migration
  def self.up
    add_column :movie_languages, :position, :integer, :default => 9999, :null => false
  end

  def self.down
    remove_column :movie_languages, :position
  end
end
