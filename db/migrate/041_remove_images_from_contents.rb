class RemoveImagesFromContents < ActiveRecord::Migration
  def self.up
    remove_column :images, :page_id
    add_column :images, :description, :string
  end

  def self.down
    add_column :images, :page_id, :integer
    remove_column :images, :description
  end
end
