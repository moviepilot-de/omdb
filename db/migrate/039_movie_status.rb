class MovieStatus < ActiveRecord::Migration
  def self.up
    add_column :movies, :status, :string, :default => 'Released', :null => false
  end

  def self.down
    remove_column :movies, :status
  end
end
