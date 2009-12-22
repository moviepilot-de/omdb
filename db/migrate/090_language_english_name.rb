class LanguageEnglishName < ActiveRecord::Migration
  def self.up
    Country.find_all.each { |c|
      a = c.aliases.local( Locale.base_language )
      if a.empty?
        a = NameAlias.new( :country => c, :language => Locale.base_language )
      else
        a = a.first
      end
      a.name = c.english_name
      a.save
    }
  end

  def self.down
  end
end
