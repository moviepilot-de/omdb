class CreateImages < ActiveRecord::Migration
  def self.up
    create_table :images do |t|
      t.column "data", :binary, :default => "", :null => false
      t.column "release_id", :integer, :default => 0, :null => false
      t.column "movie_id", :integer, :default => 0, :null => false
      t.column "person_id", :integer, :default => 0, :null => false
    end
  end

  def self.down
    drop_table :images
  end
end
