class OfficialTranslation < ActiveRecord::Migration
  def self.up
    add_column :name_aliases, :official_translation, :boolean, :default => false
    remove_column :name_aliases, :actor_id
    remove_column :name_aliases, :category_id
    remove_column :name_aliases, :character_id
    remove_column :name_aliases, :company_id
    remove_column :name_aliases, :country_id
    remove_column :name_aliases, :image_id
    remove_column :name_aliases, :job_id
    remove_column :name_aliases, :movie_id
    remove_column :name_aliases, :person_id
    
    add_index :name_aliases, [ :related_object_id, :related_object_type, :language_id ], :name => 'related_object_language_idx'
    add_index :name_aliases, [ :related_object_id, :related_object_type, :language_id, :official_translation ], :name => 'official_translation_idx'
    remove_index :name_aliases, :name => 'aliases_actor_id_index'
    remove_index :name_aliases, :name => 'aliases_movie_language'
    remove_index :name_aliases, :name => 'aliases_image_language'
    remove_index :name_aliases, :name => 'aliases_category_language'
  end

  def self.down
    remove_index :name_aliases, :name => 'related_object_language_idx'
    remove_index :name_aliases, :name => 'official_translation_idx'

    remove_column :name_aliases, :official_translation
    add_column :name_aliases, :actor_id, :integer
    add_column :name_aliases, :category_id, :integer
    add_column :name_aliases, :character_id, :integer
    add_column :name_aliases, :company_id, :integer
    add_column :name_aliases, :country_id, :integer
    add_column :name_aliases, :image_id, :integer
    add_column :name_aliases, :job_id, :integer
    add_column :name_aliases, :movie_id, :integer
    add_column :name_aliases, :person_id, :integer
  end
end
