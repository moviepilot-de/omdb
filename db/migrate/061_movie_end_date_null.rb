class MovieEndDateNull < ActiveRecord::Migration
  def self.up
    change_column :movies, :end, :date, :null => true, :default => nil
  end

  def self.down
    change_column :movies, :end, :date, :null => false
  end
end
