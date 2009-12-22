class FixDefaultDate < ActiveRecord::Migration
  def self.up
    remove_column :principals, :created_at
    add_column :principals, :created_at, :datetime, :null => true
  end

  def self.down
    change_column :principals, :created_at, :datetime, :null => false, :default => Time.now
  end
end
