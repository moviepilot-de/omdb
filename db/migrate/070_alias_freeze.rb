class AliasFreeze < ActiveRecord::Migration
  def self.up
    add_column :name_aliases, :frozen, :boolean, :default => 0
    add_column :name_aliases, :company_id, :integer
    add_column :name_alias_versions, :frozen, :boolean, :default => 0
    add_column :name_alias_versions, :company_id, :integer

    add_index :name_aliases, [ :movie_id, :language_id ], :name => 'aliases_movie_language'
    add_index :name_aliases, [ :image_id, :language_id ], :name => 'aliases_image_language'
    add_index :name_aliases, [ :category_id, :language_id ], :name => 'aliases_category_language'
    add_index :name_aliases, :person_id, :name => 'aliases_person'
    add_index :name_aliases, :company_id, :name => 'aliases_company'
  end

  def self.down
     remove_column :name_aliases, :frozen
     remove_column :name_aliases, :company_id
     remove_column :name_alias_versions, :frozen
     remove_column :name_alias_versions, :company_id

     remove_index :name_aliases, :name => 'aliases_movie_language'
     remove_index :name_aliases, :name => 'aliases_image_language'
     remove_index :name_aliases, :name => 'aliases_category_language'
     remove_index :name_aliases, :name => 'aliases_person'
     remove_index :name_aliases, :name => 'aliases_company'
  end
end
