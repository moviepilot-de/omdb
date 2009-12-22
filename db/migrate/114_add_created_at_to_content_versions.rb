class AddCreatedAtToContentVersions < ActiveRecord::Migration
  def self.up
    add_column :content_versions, 'created_at', :datetime
    execute 'update content_versions set created_at = updated_at'
  end

  def self.down
    remove_column :content_versions, 'created_at'
  end
end
