class AssignableCategory < ActiveRecord::Migration
  def self.up
    add_column :categories, :assignable, :boolean, :default => true
  end

  def self.down
    remove_column :categories, :assignable
  end
end
