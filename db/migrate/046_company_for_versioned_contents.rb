class CompanyForVersionedContents < ActiveRecord::Migration
  def self.up
    add_column :content_versions, :company_id, :integer, :default => 0, :null => false
  end

  def self.down
    drop_column :content_versions, :company_id
  end
end
