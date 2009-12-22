class CompanyParent < ActiveRecord::Migration
  def self.up
    add_column :companies, :parent_id, :integer 
    add_index :companies, :parent_id
  end

  def self.down
    remove_column :companies, :parent_id
  end
end
