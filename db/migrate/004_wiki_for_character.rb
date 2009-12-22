class WikiForCharacter < ActiveRecord::Migration
  def self.up
    add_column :contents, :character_id, :integer, :null => true, :default => 0
  end

  def self.down
    drop_column :contents, :character_id
  end
end
