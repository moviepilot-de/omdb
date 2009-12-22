class CountryLocalName < ActiveRecord::Migration
  def self.up
    add_column :name_aliases, :country_id, :integer
  end

  def self.down
    remove_column :name_aliases, :country_id
  end
end
