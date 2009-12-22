class OptimizeIndices < ActiveRecord::Migration
  def self.up
    add_index :log_entries, [ :related_object_type, :related_object_id ], :name => 'related_object_index'
    add_index :contents, [ :related_object_type, :related_object_id, :page_name, :language_id, :type ], :name => 'content_default_index'
    add_index :movie_languages, [ :movie_id, :language_id ], :name => 'movie_language_index'
    add_index :movies, [ :parent_id ], :name => 'movie_parent_index'
    add_index :users, [ :login ], :name => 'login_index'
    add_index :users, [ :email ], :name => 'email_index'
    add_index :votes, [ :movie_id, :user_id ], :name => 'votes_default_index'
    add_index :categories, [ :parent_id ], :name => 'categories_parent_index'
    remove_index :movie_user_categories, :name => 'movie_user_categories_category_id_index'
    remove_index :movie_user_categories, :name => 'movie_user_categories_movie_id_index'
  end

  def self.down
    remove_index :log_entries, :name => 'related_object_index'
    remove_index :contents, :name => 'content_default_index'
    remove_index :movie_languages, :name => 'movie_language_index'
    remove_index :movies, :name => 'movie_parent_index'
    remove_index :users, :name => 'login_index'
    remove_index :users, :name => 'email_index'
    remove_index :votes, :name => 'votes_default_index'
    remove_index :categories, :name => 'categories_parent_index'
    add_index :movie_user_categories, [ :movie_id ], :name => 'movie_user_categories_movie_id_index'
    add_index :movie_user_categories, [ :movie_id ], :name => 'movie_user_categories_category_id_index'
  end
end
