module LocalName
  def local_name( lang = Locale.base_language )
    cat_alias = aliases.local(lang) if not lang.nil?
    if cat_alias.nil? or cat_alias.empty?
      cat_alias = aliases.local( Locale.base_language )
    end
    if cat_alias.first.nil?
      logger.info "Object #{self.class} with id #{id} has no aliases"
      if not self['name'].nil?
        return self['name']
      else
        return ""
      end
    end
    cat_alias.first.name
  end

  def name
    local_name Locale.base_language
  end

  def aliases
    name_aliases
  end

  def local_aliases( lang )
    aliases.local( lang )
  end

  def official_translation( lang )
    self.aliases.find(:all, :conditions => [ "official_translation = ? AND language_id = ?", 1, lang.id ] )
  end

  def non_official_aliases( lang )
    aliases - official_translation( lang )
  end
  
  def non_official_translations( lang )
    self.aliases.find(:all, :conditions => [ "official_translation = ? AND (language_id = ? OR language_id = ?) ", 0, lang.id, Language.independent_language.id ] )
  end
  
  def no_official_translation( lang )
    self.official_translation( lang ).each do |a|
      a.official_translation = false
      a.save
    end
  end

  # problem - sporadic MemCache Error: undefined class/module NameAlias errors
  # TODO expire cached objects when aliases change
  # TODO caches_method :aliases_by_language generiert caching wrapper
  # automatisch
  def aliases_by_language
 #   key = "aliases_by_language_#{self.class.base_class}_#{self.id}"
 #   unless aliases = Cache.get(key)
      aliases = {}
      NameAlias.find(:all, :conditions => "related_object_type = '#{self.class.base_class}' and related_object_id = #{self.id}").each { |a|
        aliases[a.language] ||= []
        aliases[a.language] << a
      }
#      Cache.put key, aliases
#    end
    aliases
  end
  
  # Return aliases in a slimed down version of aliases_by_language (needed for
  # indexing)
  # 
  # >> Movie.find(11).alias_names_by_language
  # => {"de"=>["Der Herr der Ringe"]}
  def alias_names_by_language
    returning aliases = {} do 
      aliases_by_language.each do |lang, as|
        aliases[lang.code] = as.collect{ |a| a.name }
      end
    end
  end
end
