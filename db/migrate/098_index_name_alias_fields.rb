class IndexNameAliasFields < ActiveRecord::Migration
  def self.up
    add_index (:name_aliases, [:related_object_type, :related_object_id], :name => 'related_object_idx')
  end

  def self.down
    remove_index :name_aliases, :name => 'related_object_idx'    
  end
end
