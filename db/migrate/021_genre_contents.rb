class GenreContents < ActiveRecord::Migration
  def self.up
    add_column :contents, :genre_id, :string, :default => 0, :null => false
  end

  def self.down
  end
end
