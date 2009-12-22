class CompanyToTrailer < ActiveRecord::Migration
  def self.up
    add_column :trailers, :company_id, :integer
  end

  def self.down
    remove_column :trailers, :company_id
  end
end
