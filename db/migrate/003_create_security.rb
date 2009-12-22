class CreateSecurity < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.column "login", :string, :limit => 255
      t.column "password", :string, :limit => 255
    end
    create_table :authorities do |t|
      t.column "user_id", :integer, :default => 0, :null => false
      t.column "authority", :string, :limit => 50
    end
  end

  def self.down
    drop_table :authorities
    drop_table :users
  end
end
