class ExtendedPrivileges < ActiveRecord::Migration

  def self.up
    add_column :privilege_s, :klass, :string, :limit => 64, :default => "Class", :null => false
    # Ben: Ich hatte diesen index gar nicht .. 
    # remove_index :privilege_s, :name
    add_index :privilege_s, ["klass", "name"], :name => "klass_name", :unique => true
  end

  def self.down
    execute "UPDATE privilege_s SET name = concat(klass, '::', name)"
    remove_index :privilege_s, :klass_name
    remove_column :privilege_s, :klass
    add_index :privilege_s, ["name"], :name => "name", :unique => true
  end
  
end
