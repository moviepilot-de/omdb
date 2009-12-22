module WikiEnabled

  # Display Title to display a different title then the name .. needed for 
  # wiki links like [[m:1|display text]]
  attr :display_title, true

  # override to restrict access to pages belonging to this model.
  # needed for user pages, which may only be edited by the user they 
  # belong to
  def may_edit_pages(user)
    true
  end

  def has_wiki_index?( lang )
    Content.count(self.page_conditions('index', lang)) > 0
  end

  def has_more_pages?(lang)
    pages.local(lang).size > 1
  end

  def wiki_index( lang )
    page 'index', lang
  end

  def page( pname, lang, title = nil )
    pname = 'index' if pname.to_s.blank?
    page = find_page(pname, lang)
    unless page
      page = Page.new(:page_name => pname, :language => lang, :name => pname, :related_object => self)
      page.save! if pname == 'index'
    end
    page.display_title = title unless title.to_s.blank?
    page
  end

  def find_page(pname, lang)
    Page.find :first, :conditions => self.page_conditions(pname, lang)
  end

  def local_pages(lang)
    pages.local(lang)
  end

  def latest_content_versions
    Content::Version.find :all, :conditions => content_conditions
  end

  def contents_by_language
    returning pages = Hash.new { |hash, key| hash[key] = [] } do
      Content.find(:all, :conditions => content_conditions).each do |p|
        pages[p.language.iso_639_1] << p
      end
    end
  end

  def abstract( lang )
    abstracts.local( lang ).first || Abstract.new( :related_object => self )
  end

  # gibt alle Sprachen zurueck, fuer die ein Abstract oder eine nicht-leere Index-Seite existiert
  def index_page_languages
    ids = connection.select_values %{select distinct language_id from contents where related_object_id = #{id} AND related_object_type = '#{toplevel_class.name}' AND data is not null AND data != '' AND ((type = 'Page' AND page_name = 'index') OR type = 'Abstract')}
    Language.find(ids)
  end


  protected

    def content_conditions
      [ "related_object_id = ? AND related_object_type = ?", 
                           id,             toplevel_class.name ]
    end

    def page_conditions(name = 'index', lang = nil)
      returning conditions = content_conditions do
        conditions.first << ' AND page_name = ?'
        conditions       << name 
        if lang
          conditions.first << ' AND language_id = ?' 
          conditions       << lang.id
        end
      end
    end


end
