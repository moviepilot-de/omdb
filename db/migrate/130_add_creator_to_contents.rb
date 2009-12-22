class AddCreatorToContents < ActiveRecord::Migration
  def self.up
    add_column :contents, 'creator_id', :integer
    add_index :content_versions, :content_id
    Content.reset_column_information
    Content.find(:all).each do |content|
      content.without_version do 
        content.update_attribute :creator_id, content.versions.first.user_id 
      end
    end
  end

  def self.down
    remove_column :contents, 'creator_id'
    remove_index :content_versions, :content_id
  end
end
