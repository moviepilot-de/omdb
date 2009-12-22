class RemoveCategoryType < ActiveRecord::Migration
  def self.up
    remove_column :categories, :category_type_id
  end

  def self.down
    add_colum "categories", "category_type_id", :integer, :default => 0, :null => false
  end
end
