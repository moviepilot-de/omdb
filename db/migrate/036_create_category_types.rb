class CreateCategoryTypes < ActiveRecord::Migration
  def self.up
    create_table :category_types do |t|
      t.column :name, :string
    end
  end

  def self.down
    drop_table :category_types
  end
end
