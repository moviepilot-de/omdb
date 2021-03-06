class CreateCountries < ActiveRecord::Migration
  def self.up
    create_table :countries do |t|
      t.column "code", :string, :limit => 2, :null => false      
      t.column "name", :string, :limit => 255, :null => false
    end
    add_index(:countries, :code, :unique => true)
  end

  def self.down
    drop_table :countries
  end
end
