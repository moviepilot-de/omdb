class ImageContent < ActiveRecord::Migration
  def self.up
    add_column :contents, :image_id, :integer
    add_column :content_versions, :image_id, :integer
    add_index :contents, :image_id
  end

  def self.down
    remove_column :contents, :image_id
    remove_column :content_versions, :image_id
  end
end
