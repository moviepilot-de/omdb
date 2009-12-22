class LanguageIndependentAsLangId1 < ActiveRecord::Migration
  def self.up
    execute "update globalize_languages set id = 1 where id = 0"
    execute "update name_aliases set language_id=1 where language_id=0"
  end

  def self.down
    execute "update globalize_languages set id = 0 where id = 1"
    execute "update name_aliases set language_id=0 where language_id=1"
  end
end
