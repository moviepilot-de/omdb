class NewMovieColumns < ActiveRecord::Migration
  def self.up
    add_column :movies, :budget, :string, :limit => 32, :default => "0", :null => false
    add_column :movies, :revenue, :string, :limit => 32, :default => "0", :null => false
  end

  def self.down
  end
end
