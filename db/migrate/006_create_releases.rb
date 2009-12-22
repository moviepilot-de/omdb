class CreateReleases < ActiveRecord::Migration
  def self.up
    create_table :releases do |t|
      t.column "name",        :string,  :limit => 100, :default => "", :null => false
      t.column "date",        :date,    :null => false
      t.column "language_id", :integer, :default => 0, :null => false
      t.column "runtime",     :integer
      t.column "barcode",     :integer, :limit => 20
    end

    create_table "movies_releases", :id => false do |t|
      t.column "movie_id",   :integer, :default => 0, :null => false
      t.column "release_id", :integer, :default => 0, :null => false
    end

    add_index "movies_releases", ["release_id"], :name => "release_id"
    add_index "movies_releases", ["movie_id"], :name => "movie_id"

    add_column :contents, :release_id, :integer, :default => 0, :null => false
  end

  def self.down
    drop_table :releases
    drop_table :movies_releases
  end
end
