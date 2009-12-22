class MovieBudgetAsInt < ActiveRecord::Migration
  def self.up
    change_column :movies, :budget, :integer, :unsigned => true
    change_column :movies, :revenue, :integer, :unsigned => true
  end

  def self.down
    change_column :movies, :budget, :string, :limit => 32
    change_column :movies, :revenue, :string, :limit => 32
  end
end
