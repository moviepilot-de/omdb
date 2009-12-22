class OptimizeMovieUserCategoriesTable < ActiveRecord::Migration
  def self.up
    add_index :movie_user_categories, [ :movie_id, :user_id, :category_id, :value ], :name => 'movie_user_category_values'
    add_index :movie_user_categories, [ :movie_id, :user_id, :category_id ], :name => 'movie_user_categories'
    add_index :movie_user_categories, [ :movie_id, :category_id ], :name => 'movie_categories'
    add_index :movie_user_categories, [ :movie_id ]
    add_index :movie_user_categories, [ :category_id ]    
  end

  def self.down
  end
end
