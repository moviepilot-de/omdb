# This is an attachable page that will be used for movies, countries, genres, etc.
# dont mix up with the WikiPage..
class Page < Content
  
  has_many :images
  
  attr :accept_license, true
  attr :display_title, true
  attr_reader :skip_indexing

  unless defined? PAGE_NAME_CONTAINS_ILLEGAL_CHARACTER
    PAGE_NAME_CONTAINS_ILLEGAL_CHARACTER = /^([^;?&|$#\\\/]+)$/
  end

  validates_uniqueness_of :page_name, 
                          :scope   => [ :related_object_id, :related_object_type, :language_id ], 
                          :message => 'That page name is already taken'.t,
                          :if      => Proc.new { |page| !page.related_object.nil? }

  validates_presence_of :page_name, :message => 'Please enter a page name.'.t

  validates_format_of :page_name, 
                      :with    => PAGE_NAME_CONTAINS_ILLEGAL_CHARACTER,
                      :message => 'Please do not use ;?&|$#\/ for the page name.'.t,
                      :if      => Proc.new { |page| !page.page_name.blank? }
  
  validates_acceptance_of :accept_license,
                          :message => "Please accept the license.".t,
                          :allow_nil => false,
                          # only check on updates, initial page creation sets no content, 
                          # so no license needs to be accepted
                          :on => :update 

  # nur autorisiertes personal darf generic_pages bearbeiten
  # Hintergrund: generic pages sind ihr eigenes related object, und diese
  # Methode wird so aufgerufen:
  # edit_link if related_object.may_edit_pages(current_user)
  # TODO: über refactoring zu besser lesbarer syntax nachdenken:
  # edit_link if current_user.may_edit_pages_of(related_object)
  def may_edit_pages(user)
    user.is_editor?  
  end

  def may_destroy?(user)
    page_name != 'index' && user && user.is_admin?
  end

  def may_rename?(user)
    page_name != 'index' && user && ( user.is_editor? || creator == user )
  end

  def accept_license_and_save!
    self.accept_license = '1'
    save!
  end

  def save_content_cache(html)
    without_version do
      @skip_indexing = true
      update_attributes :accept_license => '1', :data_html => html, :html_updated_at => Time.now.utc
    end
  end

  def name
    return page_name if related_object.nil? || related_object.name.nil?
    if page_name == "index"
      related_object.name
    else
      related_object.name + " :: " + read_attribute(:page_name)
    end
  end

  def get_version rev
    if not rev.nil? and rev.to_i > 0
      old_rev = find_version(rev)
      if not old_rev.nil?
        old_rev.current_version = self.version
        old_rev.current = self
        return old_rev
      end
    end
    return self
  end

  class << self

    # find language specific version of a generic content page or fall back
    # to the base_language, which is english
    def find_generic_page(name, language)
      generic_page_for_language(name, language) || 
        generic_page_for_language(name, Locale.base_language)
    end
    # find language specific version of a generic content page
    def generic_page_for_language(name, language)
      find(:first, 
           :conditions => [ 'page_name=? AND language_id=? AND related_object_id is null', 
                            name, language.id ])
    end
  end
  
end
