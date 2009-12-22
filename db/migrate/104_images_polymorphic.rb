class ImagesPolymorphic < ActiveRecord::Migration
  def self.up
    add_column :images, :related_object_type, :string
    add_column :images, :related_object_id, :integer
    add_column :images, :license, :integer, :default => Image::LICENSE_UNKNOWN
    add_column :images, :user_id, :integer

    [ Category, Character, Company, Job, Movie, Person ].each do |type|
      type_column = type.to_s.split("::").last.downcase
      ActiveRecord::Migration.execute "UPDATE images SET related_object_type='#{type.to_s}' WHERE #{type_column}_id > 0"
      ActiveRecord::Migration.execute "UPDATE images SET related_object_id=#{type_column}_id WHERE #{type_column}_id > 0"
    end
    
    remove_column :images, :category_id
    remove_column :images, :character_id
    remove_column :images, :company_id
    remove_column :images, :job_id
    remove_column :images, :movie_id
    remove_column :images, :person_id
    remove_column :images, :release_id

    add_index :images, [ :related_object_id, :related_object_type ]
    add_index :images, :license
    add_index :images, :user_id    
  end

  def self.down
    add_column :images, :category_id, :integer
    add_column :images, :character_id, :integer
    add_column :images, :company_id, :integer
    add_column :images, :job_id, :integer
    add_column :images, :movie_id, :integer
    add_column :images, :person_id, :integer
    add_column :images, :release_id, :integer
    
    remove_column :images, :related_object_type
    remove_column :images, :related_object_id
    remove_column :images, :license
  end
end
