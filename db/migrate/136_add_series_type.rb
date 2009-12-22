class AddSeriesType < ActiveRecord::Migration
  def self.up
    add_column :movies, :series_type, :string, :default => 'season_based'
  end

  def self.down
    remove_column :movies, :series_type
  end
end
