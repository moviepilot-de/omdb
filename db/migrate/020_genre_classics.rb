class GenreClassics < ActiveRecord::Migration

  def self.up
    remove_column :genres, :example_movie1
    remove_column :genres, :example_movie2
    remove_column :genres, :example_movie3
    
    create_table :genres_classics, :id => false, :force => true do |t|
      t.column :genre_id, :integer, :null => false
      t.column :movie_id, :integer, :null => false
    end
    add_index :genres_classics, [:genre_id, :movie_id], :unique => true    
  end
    
  def self.down
    drop_table :genres_classics
    add_column :genres, :example_movie1, :integer, :null => true
    add_column :genres, :example_movie2, :integer, :null => true
    add_column :genres, :example_movie3, :integer, :null => true    
  end

end