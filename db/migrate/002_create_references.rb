class CreateReferences < ActiveRecord::Migration
  def self.up
    create_table :movie_references do |t|
      t.column "type", :string, :limit => 50
      t.column "movie_id", :integer, :default => 0, :null => false
      t.column "referenced_id", :integer, :default => 0, :null => false
      t.column "position", :integer, :default => 999, :null => false
    end
    add_index "movie_references", ["movie_id"], :name => "movie_id"
    add_index "movie_references", ["referenced_id"], :name => "referenced_id"
  end

  def self.down
    drop_table :movie_references
  end
end
