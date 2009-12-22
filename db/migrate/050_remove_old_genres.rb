class RemoveOldGenres < ActiveRecord::Migration
  def self.up
    drop_table :genres
    drop_table :movie_genres
    drop_table :genres_classics
  end

  def self.down
    create_table "genres", :force => true do |t|
      t.column "parent_id", :integer
      t.column "name", :string, :limit => 200, :default => "", :null => false
      t.column "position", :integer, :default => 0
    end

    create_table "genres_classics", :id => false, :force => true do |t|
      t.column "genre_id", :integer, :default => 0, :null => false
      t.column "movie_id", :integer, :default => 0, :null => false
    end

    add_index "genres_classics", ["genre_id", "movie_id"], :name => "genres_classics_genre_id_index", :unique => true
    
    create_table "movie_genres", :id => false, :force => true do |t|
      t.column "movie_id", :integer, :default => 0, :null => false
      t.column "genre_id", :integer, :default => 0, :null => false
      t.column "position", :integer, :default => 0, :null => false
    end
  end
end
