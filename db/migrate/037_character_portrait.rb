class CharacterPortrait < ActiveRecord::Migration
  def self.up
    add_column :images, :character_id, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :images, :character_id
  end
end
