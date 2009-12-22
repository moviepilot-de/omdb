class CharacterAliases < ActiveRecord::Migration
  def self.up
    add_column "name_aliases", "character_id", :integer
    add_column "name_alias_versions", "character_id", :integer
  end

  def self.down
    remove_column "name_aliases", "character_id"
    remove_column "name_alias_versions", "character_id"
  end
end
