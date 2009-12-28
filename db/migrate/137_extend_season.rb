class ExtendSeason < ActiveRecord::Migration
  def self.up
    add_column :movies, :season_type, :string, :default => 'regular'
  end

  def self.down
    remove_column :movies, :season_type
  end
end
