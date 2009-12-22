class Media < ActiveRecord::Migration
  def self.up
    add_column :contents, :medium_id, :integer, :default => 0, :null => false
    add_column :media, :frozen, :boolean, :default => false, :null => false
    add_column :media, :position, :integer, :default => 9999, :null => false
    add_column :movies_releases, :frozen, :boolean, :default => false, :null => false
    add_column :movies_releases, :position, :integer, :default => 9999, :null => true
  end

  def self.down
  end
end
