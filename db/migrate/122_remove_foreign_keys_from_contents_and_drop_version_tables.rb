class RemoveForeignKeysFromContentsAndDropVersionTables < ActiveRecord::Migration
  def self.up
    %w(movie_id person_id character_id medium_id genre_id country_id category_id company_id job_id image_id).each do |col|
      remove_column :contents, col
      remove_column :content_versions, col
    end
    drop_table :cast_versions
    drop_table :character_versions
    drop_table :name_alias_versions
    drop_table :person_versions
    drop_table :reference_versions
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
