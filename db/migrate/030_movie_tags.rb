class MovieTags < ActiveRecord::Migration
  def self.up
    # drop old tag tables
    drop_table :tags
    drop_table :taggings
    
    create_table :categories do |t|
      # parent tag
      t.column :category_id, :int
    end
    
    create_table :movie_user_categories do |t|
      t.column :category_id, :integer
      t.column :movie_id, :integer
      t.column :user_id, :integer
    end
    
    create_table :category_aliases do |t|
      t.column :name, :string
      t.column :language_id, :integer
      t.column :page_id, :integer
    end
  end

  def self.down
    drop_table :categories
    drop_table :category_aliases
    drop_table :movie_user_categories
    
    # recreate old tag tables
    create_table :tags do |t|
      t.column :name, :string, :limit => 24, :null => false
    end
    add_index :tags, [:name], :unique => true

    create_table :taggings do |t|
      t.column :tag_id, :integer, :null => false
      t.column :taggable_id, :integer, :null => false
      t.column :taggable_type, :string, :limit => 24, :null => false
    end
    add_index :taggings, [:taggable_type, :taggable_id], :unique => true
  end
end
