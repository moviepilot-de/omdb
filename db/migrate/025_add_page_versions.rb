class AddPageVersions < ActiveRecord::Migration
  def self.up
    Content.create_versioned_table
  end

  def self.down
    Content.drop_versioned_table
  end
end
