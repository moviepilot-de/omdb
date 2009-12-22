class MovieEditState < ActiveRecord::Migration
  def self.up
    add_column :movies, :edit_status, :string, :null => false, :default => 'Abandoned'
    add_column :movie_versions, :edit_status, :string, :null => false, :default => 'Abandoned'
    add_column :people, :edit_status, :string, :null => false, :default => 'Abandoned'
    add_column :person_versions, :edit_status, :string, :null => false, :default => 'Abandoned'
  end

  def self.down
    remove_column :movies, :edit_status
    remove_column :movie_versions, :edit_status
    remove_column :people, :edit_status
    remove_column :person_versions, :edit_status
  end
end
