class CompanyContent < ActiveRecord::Migration
  def self.up
    add_column :contents, :company_id, :integer, :default => 0, :null => false
  end

  def self.down
    drop_column :contents, :company_id
  end
end
