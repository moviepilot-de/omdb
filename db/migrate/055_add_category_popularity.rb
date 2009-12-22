class AddCategoryPopularity < ActiveRecord::Migration
  def self.up
    add_column :categories, :popularity, :integer, :default => 0
  end

  def self.down
    remove_column :categories, :popularity
  end
end
