class DropOldTables < ActiveRecord::Migration
  def self.up
    remove_column :content_versions, :release_id
    remove_column :contents, :release_id

    drop_table :covers
    drop_table :media
    drop_table :movies_releases
    drop_table :releases
    drop_table :category_types
    drop_table :movie_contents
  end

  def self.down
    add_column :content_versions, :release_id, :integer, :default => 0
    add_column :contents, :release_id, :integer, :default => 0

    create_table "covers", :force => true do |t|
      t.column "release_id", :integer, :default => 0, :null => false
      t.column "movie_id", :integer, :default => 0, :null => false
      t.column "data", :binary, :default => "", :null => false
      t.column "content_type", :string, :limit => 4, :default => "", :null => false
    end

    create_table "media", :force => true do |t|
      t.column "release_id", :integer, :default => 0, :null => false
      t.column "type", :string, :limit => 64
      t.column "name", :string, :limit => 64, :default => "", :null => false
      t.column "frozen", :boolean, :default => false, :null => false
      t.column "position", :integer, :default => 9999, :null => false
    end
    
    create_table "movies_releases", :id => false, :force => true do |t|
      t.column "movie_id", :integer, :default => 0, :null => false
      t.column "release_id", :integer, :default => 0, :null => false
      t.column "frozen", :boolean, :default => false, :null => false
      t.column "position", :integer, :default => 999
    end

    create_table "releases", :force => true do |t|
      t.column "name", :string, :limit => 100, :default => "", :null => false
      t.column "date", :date, :null => false
      t.column "language_id", :integer, :default => 0, :null => false
      t.column "runtime", :integer
      t.column "barcode", :integer, :limit => 20
      t.column "frozen", :boolean, :default => false, :null => false
    end

    create_table "category_types", :force => true do |t|
      t.column "name", :string
    end

    create_table "movie_contents", :force => true do |t|
      t.column "movie_id", :integer, :default => 0, :null => false
      t.column "language_id", :integer, :default => 0, :null => false
      t.column "data", :text, :default => "", :null => false
    end
  end
end
