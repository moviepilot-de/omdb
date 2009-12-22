class AddTagTreeColumn < ActiveRecord::Migration
  def self.up
    rename_column :categories, :category_id, :parent_id
    add_column :category_aliases, :category_id, :integer, :null => false
  end

  def self.down
    rename_column :categories, :parent_id, :category_id
    remove_column :category_aliases, :category_id
  end
end
