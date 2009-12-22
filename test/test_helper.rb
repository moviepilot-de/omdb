ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'
require File.expand_path(File.dirname(__FILE__) + '/test_omdb_helper')
require File.expand_path(File.dirname(__FILE__) + '/wiki_test_helper')
require File.expand_path(File.dirname(__FILE__) + '/helper_testcase')
require File.expand_path(File.dirname(__FILE__) + '/dsl')

class Test::Unit::TestCase
  include AuthenticatedTestHelper, WikiTestHelper
  fixtures :users, :globalize_languages
  set_fixture_class(:globalize_languages => "Language")

  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures  = false

  # Add more helper methods to be used by all tests here...
  
  protected

  #def self.reindex( classes )
  #  Indexer.reset
  #  classes.each do |klass|
  #    Indexer.index_all klass
  #  end
  #end
end

class SearchObserver
  def after_create(record)
    (@records ||= []) << record
  end
  def cleanup
    @records.each do |record|
      Indexer.get_writer do |writer|
        Indexer.delete_local( { :type => record.base_class_name, :id => record.id }, writer )
      end
    end if @records
  end
end

Time.class_eval do
  class << self
    alias_method :real_now, :now
  end

  def self.mock_now
    @current_time
  end

  def self.mock!(time)
    class << Time ; alias_method :now, :mock_now; end
    @current_time = time
    yield
    class << Time ; alias_method :now, :real_now; end
  end
end

