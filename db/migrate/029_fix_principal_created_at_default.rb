class FixPrincipalCreatedAtDefault < ActiveRecord::Migration
  def self.up
    change_column :principals, :created_at, :datetime
  end

  def self.down
    change_column :principals, :created_at, :date, :default => Time.now
  end
end
