class RemoveObsoleteTables < ActiveRecord::Migration
  def self.up
    drop_table :principals
    drop_table :principals_privileges
    drop_table :privilege_s
    drop_table :signup_confirmations
    drop_table :groups_users
    drop_table :authorities
  end

  def self.down
    raise IrreversibleMigration
  end
end
