class FixGlobalize < ActiveRecord::Migration
  def self.up
    add_column :globalize_translations, :built_in, :boolean
    Translation.delete_all "language_id = 1556"
  end

  def self.down
    remove_column :globalize_translations, :built_in
  end
end
