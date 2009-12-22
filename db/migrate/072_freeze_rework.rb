class FreezeRework < ActiveRecord::Migration
  def self.up
    remove_column :casts, :frozen
    remove_column :cast_versions, :frozen
    remove_column :movie_references, :frozen
    remove_column :reference_versions, :frozen
    remove_column :movies, :frozen
    remove_column :movie_versions, :frozen
    remove_column :name_aliases, :frozen
    remove_column :production_companies, :frozen

  end

  def self.down
    add_column :casts, :frozen, :boolean, :default => false
    add_column :cast_versions, :frozen, :boolean, :default => false
    add_column :movie_references, :frozen, :boolean, :default => false
    add_column :reference_versions, :frozen, :boolean, :default => false
    add_column :movies, :frozen, :boolean, :default => false
    add_column :movie_versions, :frozen, :boolean, :default => false
    add_column :name_aliases, :frozen, :boolean, :default => false
    add_column :production_companies, :frozen, :boolean, :default => false
  end
end
