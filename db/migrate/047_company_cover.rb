class CompanyCover < ActiveRecord::Migration
  def self.up
    add_column :images, :company_id, :integer, :default => 0, :null => false
  end

  def self.down
    drop_column :images, :company_id
  end
end
