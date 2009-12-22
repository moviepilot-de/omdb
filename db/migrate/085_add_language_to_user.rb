class AddLanguageToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :language_id, :integer
  end

  def self.down
    remove_column :users, :language_id
  end
end
