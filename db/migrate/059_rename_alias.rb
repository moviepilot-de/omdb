class RenameAlias < ActiveRecord::Migration
  def self.up
    rename_table :aliases, :name_aliases
  end

  def self.down
    rename_table :name_aliases, :aliases
  end
end
