# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')


RAILS_GEM_VERSION = '1.1.6' unless defined? RAILS_GEM_VERSION


require "#{RAILS_ROOT}/lib/ar_base_ext"

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence those specified here
  
  # Skip frameworks you're not going to use
  # config.frameworks -= [ :action_web_service ]

  # Add additional load paths for your own custom dirs
  config.load_paths += Dir["#{RAILS_ROOT}/app/models/[a-z]*"]
  config.load_paths += Dir["#{RAILS_ROOT}/app/controllers/[a-z]*"]
  config.load_paths += Dir["#{RAILS_ROOT}/lib/omdb/[a-z]*"]

  config.load_paths += %W(
    #{RAILS_ROOT}/vendor/RedCloth-3.0.4/lib
    #{RAILS_ROOT}/vendor/plugins/acts_as_versioned/lib
    #{RAILS_ROOT}/vendor/plugins/exception_notification/lib/
  )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake create_sessions_table')
  # config.action_controller.session_store = :active_record_store

  # Enable page/fragment caching by setting a file-based store
  # (remember to create the caching directory and make it readable to the application)
  # config.action_controller.fragment_cache_store = :file_store, "#{RAILS_ROOT}/cache"
  #

  # Activate observers that should always be running
  #better use observer :yourobserver in application controller
  #config.active_record.observers = :search_observer, :movie_observer, :category_observer

  # Make Active Record use UTC-base instead of local time
  config.active_record.default_timezone = :utc
  
  # Use Active Record's schema dumper instead of SQL when creating the test database
  # (enables use of different database adapters for development and test environments)
  # config.active_record.schema_format = :ruby
end

# Globalize Support
$KCODE = 'u'
require 'jcode'
require 'ferret'
require 'RMagick'

include Globalize

Locale.set_base_language 'en-US'

# Load extensions to standard model classes
[ "app/models/lib" ].each do |path|
  Dir["#{RAILS_ROOT}/#{path}/*.rb"].each do |file|
    load file
  end
end

# Add project-specific pluralization rules
Inflector.inflections do |inflect|
  inflect.uncountable 'encyclopedia'
   inflect.irregular 'director_of_photography', 'directors_of_photography'
end

LOCALES = { 'en' => 'en-US',
            'de' => 'de-DE',
            'fr' => 'fr-FR',
            'pl' => 'pl-PL',
	    'es' => 'es-ES' }.freeze

ENV['LC_CTYPE'] = 'en_US.UTF-8'
Ferret.locale = "en_US.UTF-8"

FULL_POLISH_STOP_WORDS = []

require 'omdb'

require 'cached_model'
require 'indexer'
include OMDB::Ferret

memcache_options = {
  :c_threshold => 10_000,
  :compression => true,
  :debug => false,
  :namespace => "omdb_#{RAILS_ENV}",
  :readonly => (RAILS_ENV == 'test'),
  :urlencode => false
}
CACHE = MemCache.new memcache_options
CACHE.servers = 'localhost:11211'
