class ChangeWikiPageForCategories < ActiveRecord::Migration
  def self.up
    remove_column :category_aliases, :page_id
  end

  def self.down
    add_column :category_aliases, :page_id, :integer
  end
end
