class AddedSecurity < ActiveRecord::Migration
  def self.up
    # drop_table :authorities
    # drop_table :users
    
    create_table "principals", :force => true do |t|
      t.column "type", :string, :limit => 5, :null => false
      t.column "name", :string, :limit => 64, :default => "", :null => false
      t.column "description", :string, :default => "", :null => false
      t.column "hashword", :string, :limit => 40
      t.column "first_name", :string, :limit => 127
      t.column "last_name", :string, :limit => 127
      t.column "email", :string, :limit => 127
    end

    add_index "principals", ["name"], :name => "name", :unique => true

    create_table "privilege_s", :force => true do |t|
      t.column "name", :string, :limit => 64, :default => "", :null => false
    end

    add_index "privilege_s", ["name"], :name => "name", :unique => true

    create_table "groups_users", :id => false, :force => true do |t|
      t.column "group_id", :integer, :default => 0, :null => false
      t.column "user_id", :integer, :default => 0, :null => false
    end

    add_index "groups_users", ["user_id"], :name => "user_id"

    create_table "principals_privileges", :id => false, :force => true do |t|
      t.column "principal_id", :integer, :default => 0, :null => false
      t.column "privilege_id", :integer, :default => 0, :null => false
    end

    add_index "principals_privileges", ["principal_id", "privilege_id"], :unique => true
  end

  def self.down
    drop_table :principals
    drop_table :privilege_s
    drop_table :groups_users
    drop_table :principals_privileges

    create_table :users do |t|
      t.column "login", :string, :limit => 255
      t.column "password", :string, :limit => 255
    end
    create_table :authorities do |t|
      t.column "user_id", :integer, :default => 0, :null => false
      t.column "authority", :string, :limit => 50
    end
  end
  
end
