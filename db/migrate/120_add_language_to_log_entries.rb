class AddLanguageToLogEntries < ActiveRecord::Migration
  def self.up
    add_column :log_entries, 'language_id', :integer
  end

  def self.down
    remove_column :log_entries, 'language_id'
  end
end
