class CategoryCover < ActiveRecord::Migration
  def self.up
    add_column :images, :category_id, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :images, :category_id
  end
end
