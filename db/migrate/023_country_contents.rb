class CountryContents < ActiveRecord::Migration
  def self.up
    add_column :contents, :country_id, :integer, :default => 0, :null => false

    add_index :contents, :country_id, :name => 'country_contents'
  end

  def self.down
    drop_column :contents, :country_id
  end
end
