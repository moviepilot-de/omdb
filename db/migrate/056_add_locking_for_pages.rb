class AddLockingForPages < ActiveRecord::Migration
  def self.up
    remove_column :contents, :category_alias_id
    add_column :contents, :locked, :boolean, :default => false
    add_column Content.versioned_table_name, :locked, :boolean
  end

  def self.down
    remove_column :contents, :locked
    remove_column Content.versioned_table_name, :locked
    add_column :contents, :category_alias_id, :integer
  end
end
