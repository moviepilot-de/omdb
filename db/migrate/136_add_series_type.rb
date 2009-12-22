class AddSeriesType < ActiveRecord::Migration
  def self.up
    add_column :movies, :series_type, :string
  end

  def self.down
    remove_column :movies, :series_type
  end
end
