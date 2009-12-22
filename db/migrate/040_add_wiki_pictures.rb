class AddWikiPictures < ActiveRecord::Migration
  def self.up
    add_column :images, :page_id, :integer
    add_column :images, :content_type, :string
    add_column :images, :original_filename, :string
  end

  def self.down
    remove_column :images, :page_id
    remove_column :images, :content_type
    remove_column :images, :original_filename
  end
end
