require "digest/sha1"
class User < ActiveRecord::Base
  include WikiEnabled
  
  # Virtual attribute for the unencrypted password
  attr_accessor :password, :ip_address
  attr_writer :signup_mail

  has_permalink :login
  
  has_many :contents
  
  has_many :movie_user_categories,
           :dependent => :delete_all
  
  has_many :reviews
  
  has_many :movie_user_tags,
           :dependent => :delete_all
  
  has_many :movies, :through => :movie_user_tags
  
  has_many :log_entries,
           :order => 'created_at DESC'

  # localized wiki pages
  has_many :pages,
           :as        => :related_object,
           :extend    => LocalFinder,
           :order     => :name,
           :dependent => true
           
  has_one  :image,
           :as        => :related_object,
           :dependent => :destroy

  belongs_to :country
  belongs_to :language

  validates_presence_of     :login, :email

  validates_presence_of     :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => Proc.new { |r| r.password_required? && !r.password.blank? }
  validates_confirmation_of :password,                   :if => :password_required?

  validates_format_of       :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/, :if => Proc.new { |r| !r.email.blank? }
  validates_length_of       :login, :within => 3..40, :if => Proc.new { |r| !r.login.blank? }
  validates_length_of       :email, :within => 3..100, :if => Proc.new { |r| !r.email.blank? }
  validates_uniqueness_of   :login, :email, :case_sensitive => false
  
  # relativ strikte login-format-validierung, weil sonst uniqueness des
  # permalinks nicht sichergestellt wäre
  validates_format_of       :login, :with => /^[a-z0-9\-_]+$/i, 
                            :if => Proc.new { |r| !r.login.blank? }, 
                            :message => 'Login may only contain letters a-z, underscore ("_"), numbers and hyphen ("-").'.t

  # prevent these from being set via url parameters
  attr_protected :is_admin, :is_editor, :is_chiefeditor, :permalink

  before_save :encrypt_password, :set_flags
  before_create :make_activation_code

  def display_title
    anonymous? ? 'anonymous' : login
  end

  def all_movies_paged( page = 1, tag = 'default')
    movies.find(:all, :page => { :size => 24, :current => page}, :conditions => [ 'tag = ?', tag.downcase ])
  end
  
  def all_created_movies_paged( page = 1 )
    Movie.find(:all, :page => { :size => 24, :current => page}, :conditions => [ 'creator_id = ?', self.id ], :order => 'id DESC')
  end
  
  def delete_tagged_movie( movie, tag = 'default' )
    MovieUserTag.destroy_all( [ 'movie_id = ? and tag = ? and user_id = ?', movie.id, tag, self.id ] )
  end
  
  def last_edited_movies
    Movie.find_by_sql("SELECT DISTINCT movies.* FROM movies INNER JOIN log_entries as logs ON movies.id = logs.related_object_id
                       WHERE logs.user_id = #{self.id} AND logs.related_object_type = 'Movie' ORDER BY logs.created_at DESC LIMIT 5")
  end
  
  class <<self
    # return the anonymous user
    def anonymous
      find :first, :conditions => ["login='anonymous'"]
    end
    
    def create_anonymous
      return false unless self.anonymous.nil?
      connection.execute "insert into users(login, email, name) values ('anonymous', 'anonymous@omdb.org', 'Anonymous user')"
    end

    # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
    def authenticate(login, password)
      # hide records with a nil activated_at
      u = find :first, :conditions => ['login = ? and activated_at IS NOT NULL', login]
      u && u.authenticated?(password) ? u : nil
    end

    # Encrypts some data with the salt.
    def encrypt(password, salt)
      Digest::SHA1.hexdigest("--#{salt}--#{password}--")
    end

  end

  # from WikiEnabled, overridden to restrict editing of user pages
  # this method only returns true if the given user equals *this* 
  # user, meaning he may edit pages attached to *this* user
  def may_edit_pages(user)
    return user == self
  end

  # true if this user may create / edit pages attached to the given wiki
  # enabled object
  def may_edit_pages_of_object(wiki_enabled_object)
    wiki_enabled_object.may_edit_pages self unless wiki_enabled_object.nil?
  end

  def send_signup_mail?
    @signup_mail ||= true
  end

  def forgot_password
    @forgotten_password = true
    self.make_password_reset_code
  end

  def reset_password
    # First update the password_reset_code before setting the 
    # reset_password flag to avoid duplicate email notifications.
    #update_attributes(:password_reset_code => nil)
    self.password_reset_code = nil
    @reset_password = true
  end

  def recently_reset_password?
    @reset_password
  end

  def recently_forgot_password?
    @forgotten_password
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    self.remember_token_expires_at = 2.weeks.from_now.utc
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end
  
  # Activates the user in the database.
  def activate
    @activated = true
    update_attributes(:activated_at => Time.now.utc, :activation_code => nil)
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end

  def anonymous?
    'anonymous' == login
  end

  def password_required?
    crypted_password.blank? || !password.blank?
  end
  
  def default_url(page = 'index')
    returning url = { :controller => self.class.controller_name, :id => self.permalink } do
      if page == 'index'
        url.merge! :action => 'index'
      else
        url.merge! :action => 'page', :page => page
      end
    end
  end
  
  protected
    # before_save filter
    def set_flags
      self.is_chiefeditor = true if is_admin?
      self.is_editor      = true if is_chiefeditor?
    end
    # before filter 
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
      self.crypted_password = encrypt(password)
    end

    def make_activation_code
      self.activation_code = self.class.make_random_code
    end

    def make_password_reset_code
      self.password_reset_code = self.class.make_random_code
    end

    def self.make_random_code
      Digest::SHA1.hexdigest(Time.now.to_s.split(//).sort_by {rand}.join)
    end
end
