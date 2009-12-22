class VersionHistory < ActiveRecord::Migration
  def self.up
    add_column :contents, :user_id, :integer, :default => 0, :null => true
    add_column :contents, :comment, :string
    add_column :contents, :ip, :string, :length => 15

    add_column Content.versioned_table_name, :user_id, :integer, :default => 0, :null => true
    add_column Content.versioned_table_name, :comment, :string
    add_column Content.versioned_table_name, :ip, :string, :length => 15
  end

  def self.down
    remove_column Content.versioned_table_name, :user_id
    remove_column Content.versioned_table_name, :comment
    remove_column Content.versioned_table_name, :ip
    remove_column :contents, :user_id
    remove_column :contents, :comment
    remove_column :contents, :ip
  end
end
