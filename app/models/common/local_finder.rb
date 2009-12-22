module LocalFinder
  def local( lang )
    find(:all, :conditions => [ 'language_id = ? or language_id = ?', lang.id, Language.independent_language.id ])
  end
end
