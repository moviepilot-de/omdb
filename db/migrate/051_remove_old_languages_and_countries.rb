class RemoveOldLanguagesAndCountries < ActiveRecord::Migration
  def self.up
    drop_table :languages
    drop_table :countries
    drop_table :actions
  end

  def self.down
    create_table "actions", :force => true do |t|
      t.column "parent_id", :integer
      t.column "name", :string, :limit => 100, :default => "", :null => false
      t.column "controller", :string, :limit => 100, :default => "", :null => false
      t.column "action", :string
      t.column "view", :string, :limit => 100
      t.column "type", :string, :limit => 100
      t.column "success_id", :integer
      t.column "updates", :string, :limit => 50
      t.column "confirmation", :string, :limit => 50
      t.column "icon", :string, :limit => 32
    end

    create_table "countries", :force => true do |t|
      t.column "code", :string, :limit => 2, :default => "", :null => false
      t.column "name", :string, :default => "", :null => false
    end

    create_table "languages", :force => true do |t|
      t.column "code", :string, :limit => 2, :default => "", :null => false
      t.column "active", :boolean, :default => false, :null => false
    end
  end
end
