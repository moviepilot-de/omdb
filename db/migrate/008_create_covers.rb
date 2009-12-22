class CreateCovers < ActiveRecord::Migration
  def self.up
    create_table :covers do |t|
      t.column "release_id", :integer, :default => 0, :null => false
      t.column "movie_id", :integer, :default => 0, :null => false
      t.column "data", :binary, :null => false
      t.column "content_type", :string, :limit => 4, :default => "", :null => false
    end

    add_index "covers", ["movie_id"], :name => "movie_id"
    add_index "covers", ["release_id"], :name => "release_id"
  end

  def self.down
    drop_table :covers
  end
end
