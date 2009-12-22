class CreateTrailers < ActiveRecord::Migration
  def self.up
    create_table :trailers do |t|
      t.column :movie_id, :integer, :null => false
      t.column :language_id, :integer, :null => false
      t.column :data, :longblob, :null => false
      t.column :content_type, :string, :null => false
      t.column :width, :integer, :null => false
      t.column :height, :integer, :null => false
      t.column :approved, :boolean, :default => false
    end
  end

  def self.down
    drop_table :trailers
  end
end
