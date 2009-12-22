class AddChiefEditorFlagToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :is_chiefeditor, :boolean, :default => false
  end

  def self.down
    remove_column :users, :is_chiefeditor
  end
end
