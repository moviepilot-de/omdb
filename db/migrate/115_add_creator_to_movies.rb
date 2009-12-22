class AddCreatorToMovies < ActiveRecord::Migration
  def self.up
    add_column :movies, 'creator_id', :integer
    add_column :movie_versions, 'creator_id', :integer
  end

  def self.down
    remove_column :movie_versions, 'creator_id'
    remove_column :movies, 'creator_id'
  end
end
