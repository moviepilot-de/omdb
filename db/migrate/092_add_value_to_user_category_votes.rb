class AddValueToUserCategoryVotes < ActiveRecord::Migration
  def self.up
    add_column :movie_user_categories, :value, :integer, :default => 1
      execute "UPDATE movie_user_categories SET value = 1 where 1;"
  end

  def self.down
    remove_column :movie_user_categories, :value
  end
end
