class AddImageAliases < ActiveRecord::Migration
  def self.up
    add_column :name_aliases, :image_id, :integer
    add_column NameAlias.versioned_table_name, :image_id, :integer
    change_column :name_aliases, :name, :string, :limit => 1000
    remove_column :images, :description
  end

  def self.down
    remove_column :name_aliases, :image_id
    remove_column NameAlias.versioned_table_name, :image_id
    change_column :name_aliases, :name, :string, :limit => 255
    add_column :images, :description, :string
  end
end
