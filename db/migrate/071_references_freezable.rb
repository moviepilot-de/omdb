class ReferencesFreezable < ActiveRecord::Migration
  def self.up
    add_column :movie_references, :frozen, :boolean, :default => 0
    add_column :reference_versions, :frozen, :boolean, :default => 0

    add_index :movie_references, :movie_id, :name => 'reference_movie_id'
    add_index :movie_references, :referenced_id, :name => 'referenced_movie_id'
  end

  def self.down
    remove_column :movie_references, :frozen
    remove_column :reference_versions, :frozen

    remove_index :movie_references, :name => 'reference_movie_id'
    remove_index :movie_references, :name => 'referenced_movie_id'
  end
end
