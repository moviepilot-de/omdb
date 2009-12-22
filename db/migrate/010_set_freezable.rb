class SetFreezable < ActiveRecord::Migration
  def self.up
    add_column :movies, :frozen, :boolean, :default => false, :null => false
    add_column :releases, :frozen, :boolean, :default => false, :null => false
    add_column :movie_aliases, :frozen, :boolean, :default => false, :null => false
  end

  def self.down
  end
end
