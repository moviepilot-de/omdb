class AddNoLanguageToLanguages < ActiveRecord::Migration
  def self.up
    l = Language.new
    l.iso_639_1 = 'xx'
    l.iso_639_2 = 'xx'
    l.iso_639_3 = 'xx'
    l.english_name = 'No Language'
    l.macro_language = 0
    l.direction = 'ltr'
    l.pluralization = "c == 1 ? 1 : 2"
    l.scope = 'L'
    l.save
    ActiveRecord::Migration.execute "UPDATE globalize_languages SET id = 0 WHERE english_name = 'No Language'"
  end

  def self.down
    Language.find(0).destroy
  end
end
