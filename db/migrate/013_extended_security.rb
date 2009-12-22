class ExtendedSecurity < ActiveRecord::Migration

  def self.up
    add_column :principals, :created_at, :date, :null => false
    add_column :principals, :active, :boolean, :null => false, :default => true
  end

  def self.down
    drop_column :principals, :active
    drop_column :principals, :created_at
  end
  
end