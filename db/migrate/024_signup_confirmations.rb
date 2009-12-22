class SignupConfirmations < ActiveRecord::Migration

  def self.up
    create_table :signup_confirmations, :force => true do |t|
      t.column :user_id, :integer, :null => false
      t.column :confirmation_key, :string, :limit => 40, :null => false
      t.column :created_at, :date, :null => false
    end
  
    add_index :signup_confirmations, [:confirmation_key], :name => "confirmation_key", :unique => true
    add_index :signup_confirmations, [:user_id], :name => "user_id", :unique => true
    
  end
    
  def self.down
    drop_table :signup_confirmations
  end

end