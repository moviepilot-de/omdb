class AddCategoryAliasContents < ActiveRecord::Migration
  def self.up
    add_column :contents, :category_alias_id, :integer
    add_column Content.versioned_table_name, :category_alias_id, :integer
  end

  def self.down
    remove_column :contents, :category_alias_id
    remove_column Content.versioned_table_name, :category_alias_id
  end
end
