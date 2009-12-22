class MakeContentRelatedObjectPolymorphic < ActiveRecord::Migration
  CONTENT_CLASSES = [ :category, :character, :company, :country, 
                      :image, :job, :movie, :person ]
  def self.up
    add_column :contents, :related_object_id, :integer
    add_column :contents, :related_object_type, :string
    add_column :content_versions, :related_object_id, :integer
    add_column :content_versions, :related_object_type, :string
    Content.reset_column_information
    Content.find(:all).each do |content|
      CONTENT_CLASSES.each do |sym|
        if (id = content.send :"#{sym}_id")
          obj = Object.const_get(sym.to_s.camelize).find(id) rescue nil
          next unless obj
          content.update_attribute :related_object, obj 
          execute "update content_versions set related_object_id=#{content.related_object_id}, related_object_type='#{content.related_object_type}' where content_id=#{content.id}"
        end
      end
    end
  end

  def self.down
    remove_column :content_versions, :related_object_id
    remove_column :content_versions, :related_object_type
    remove_column :contents, :related_object_type
    remove_column :contents, :related_object_id
  end
end
