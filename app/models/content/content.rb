class Content < ActiveRecord::Base
  include WikiContent

  belongs_to :creator, :class_name => 'User', :foreign_key => 'creator_id'
  belongs_to :user
  belongs_to :language
  belongs_to :related_object, :polymorphic => true
  before_save :clear_cache

  def write_log(user = User.anonymous)
    # keine neue version - kein logentry
    #last_le = log_entries.last
    #return if (last_le && last_le.new_value == version) || !version_condition_met?

    return unless related_object
    related_object.log_entries << ContentLogEntry.create(:user => user, 
                                          :ip_address  => user.ip_address, 
                                          :attribute   => id,
                                          :comment     => comment,
                                          :language_id => language_id,
                                          :old_value   => version-1,
                                          :new_value   => version) if version_condition_met?
  end

  attr_accessor :dont_create_version

  depending_objects [ :related_object ]

  acts_as_versioned do
    include WikiContent
    
    attr :current_version, true
    attr :current, true

    def user
      User.find(user_id) rescue nil
    end

    def creator
      Content.find(content_id).creator
    end

    def related_object
      Content.find(content_id).related_object
    end
    alias parent related_object
    
    def save_content_cache(html)
      update_attributes :data_html => html, :html_updated_at => Time.now.utc
    end
    
    def may_edit_pages(user)
      false
    end

    def may_destroy?(user)
      false
    end

    def may_rename?(user)
      false
    end
    
  end
  self.non_versioned_columns << 'creator_id'

  # overridden from ar_base_ext
  def default_url(*args)
    if rel_object = self.related_object
      rel_object.default_url self.page_name
    else
      # content without related_object, e.g. imprint
      { :controller => 'generic_page', :action => 'page', :page => self.page_name }
    end
  end

  def version_condition_met?
    !@dont_create_version
  end
  def without_version
    @dont_create_version = true
    yield
    @dont_create_version = false
  end

  def save_content_cache(html)
    without_version do
      update_attributes :data_html => html, :html_updated_at => Time.now.utc, :updated_at => updated_at
    end
  end

  def parent
    related_object
  end

  def current_version
    version
  end

  def current
    self
  end

  def clear_cache
    self.data_html = nil if version_condition_met? # if a new version is created, it's ok to flush the cache
  end
  
  def empty?
    data.empty?
  end
end
