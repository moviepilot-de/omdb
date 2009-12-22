class ActionIcons < ActiveRecord::Migration
  def self.up
    add_column :actions, :icon, :string, :limit => 32, :null => true
  end

  def self.down
    drop_column :actions, :icon
  end
end
