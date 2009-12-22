class AddCategoryAbstract < ActiveRecord::Migration
  def self.up
    add_column :contents, :category_id, :integer
    add_column Content.versioned_table_name, :category_id, :integer
    add_column :categories, :category_type_id, :integer, :null => false
  end

  def self.down
    remove_column :contents, :category_id
    remove_column Content.versioned_table_name, :category_id
    remove_column :categories, :category_type_id
  end
end
