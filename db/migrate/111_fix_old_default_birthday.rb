class FixOldDefaultBirthday < ActiveRecord::Migration
  def self.up
    ActiveRecord::Migration.execute "UPDATE people set birthday = NULL where birthday = '1900-01-01';"    
  end

  def self.down
  end
end
