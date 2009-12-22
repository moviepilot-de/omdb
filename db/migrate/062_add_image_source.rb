class AddImageSource < ActiveRecord::Migration
  def self.up
    add_column :images, :source, :string, :limit => 1000
  end

  def self.down
    remove_column :images, :source
  end
end
