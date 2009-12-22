class MoviePositionDefault < ActiveRecord::Migration
  def self.up
    change_column :movies, :position, :integer, :default => 9999, :null => false
  end

  def self.down
    change_column :movies, :position, :null => true
  end
end
