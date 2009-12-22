module ImageInstanceMethods

  def name
    name = self.description
    name.blank? ? self.original_filename : name
  end
  
  def filetype
    content_type.split('/').last.strip rescue 'jpeg'
  end

  def to_magick
    Magick::Image.from_blob( self.data ).first
  end

end

class Image < ActiveRecord::Base
  include WikiEnabled
  include Freezable
  include ImageInstanceMethods
  include Logging
  
  belongs_to :related_object, :polymorphic => true

  attr :display_title, true

  # accessor for old filename, used for cache expiration
  attr_reader :old_filename

  depending_objects [ :self, :related_object ]

  disable_logging_of :data, :user_id

  freezable_attribute :self

  acts_as_versioned do
    include ImageInstanceMethods
    def description
      ""
    end

    def filename
      "#{image_id}_#{version}.#{filetype}"
    end

    def user
      User.find user_id rescue nil
    end
  end
  
  # Possible Licenses
  LICENSE_UNKNOWN        = 0  unless defined?(LICENSE_UNKNOWN)
  LICENSE_DONTKNOW       = 10 unless defined?(LICENSE_DONTKNOW)
  LICENSE_FOUND          = 11 unless defined?(LICENSE_FOUND)
  LICENSE_OWNWORK        = 12 unless defined?(LICENSE_OWNWORK)
  LICENSE_FREE_CC        = 21 unless defined?(LICENSE_FREE_CC)
  LICENSE_FREE_GFDL      = 22 unless defined?(LICENSE_FREE_GFDL)
  LICENSE_FREE_WC        = 23 unless defined?(LICENSE_FREE_WC)
  LICENSE_PD_EXPIRED     = 31 unless defined?(LICENSE_PD_EXPIRED)
  LICENSE_PD_PRE_1923    = 32 unless defined?(LICENSE_PD_PRE_1923)
  LICENSE_PD_NRR         = 33 unless defined?(LICENSE_PD_NRR)
  LICENSE_FU_PERSON      = 41 unless defined?(LICENSE_FU_PERSON)
  LICENSE_FU_LOGO        = 42 unless defined?(LICENSE_FU_LOGO)
  LICENSE_FU_PROMO       = 43 unless defined?(LICENSE_FU_PROMO)
  LICENSE_FU_POSTER      = 44 unless defined?(LICENSE_FU_POSTER)
  LICENSE_FU_DVD         = 45 unless defined?(LICENSE_FU_DVD)
  LICENSE_FU_MOVIESCREEN = 46 unless defined?(LICENSE_FU_MOVIESCREEN)
  LICENSE_FU_TVSCREEN    = 47 unless defined?(LICENSE_FU_TVSCREEN)
  LICENSE_FU_OTHER       = 48 unless defined?(LICENSE_FU_OTHER)
  
  VALID_LICENSES = [ LICENSE_OWNWORK, LICENSE_FREE_CC, LICENSE_FREE_GFDL, LICENSE_FREE_WC, 
                     LICENSE_PD_EXPIRED, LICENSE_PD_PRE_1923, LICENSE_PD_NRR, LICENSE_FU_PERSON,
                     LICENSE_FU_LOGO, LICENSE_FU_PROMO, LICENSE_FU_DVD, LICENSE_FU_POSTER, 
                     LICENSE_FU_MOVIESCREEN, LICENSE_FU_TVSCREEN, LICENSE_FU_OTHER ] unless defined?(VALID_LICENSES)
  
  has_many :name_aliases, 
           :as        => :related_object,
           :extend    => LocalFinder

  # Local Copyright Information Pages
  has_many :pages,
           :as => :related_object
           
  belongs_to :user

  validates_presence_of :data
  validates_presence_of :related_object
    
  validates_each :license do |record, attribute, value|
    record.errors.add attribute, "Invalid License" unless VALID_LICENSES.include?( value.to_i )
  end

  def filename
    "#{id}.#{filetype}"
  end

  def uploaded_data=(file_data)
    return nil if file_data.nil? || file_data.size == 0 
    @old_filename = self.filename unless new_record?
    self.content_type      = file_data.content_type.strip
    self.original_filename = file_data.original_filename.strip
    self.data              = file_data.read
  end

  def description(language = Locale.base_language)
    local_names = name_aliases.local(language)
    if local_names.size > 0
      local_names.first.name
    else
      ""
    end
  end
  
  def default_url(*args)
    { :controller => 'image', :action => 'default', :fname => self.filename }
  end

end
