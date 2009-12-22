require File.dirname(__FILE__) + '/../test_helper'
require 'job_controller'

class JobController; def rescue_action(e) raise e end; end

class JobControllerTest < Test::Unit::TestCase
  include Arts
  include TestOmdbHelper

  fixtures :movies, :jobs, :name_aliases, :contents, :globalize_languages

  view_test_for :job, :director
  view_test_for :job, :director, :action => :people, :template => 'people.rhtml'
  view_test_for :job, :director, :action => :tree, :template => 'tree.rhtml', :common_tempalte => true
  view_test_for :job, :director, :action => :history, :template => 'history.rhtml', :common_tempalte => true

  abstract_test_for :job, :director, :director_abstract
  abstract_test_for :job, :director, nil
  
  # test wiki functions
  view_page_tests_for        :job, :jobs_013
  write_page_tests_for       :job, :jobs_013
  rename_page_tests_for      :job, :jobs_013
  page_destruction_tests_for :job, :jobs_013
  page_versioning_tests_for  :job, :jobs_013
  rss_link_tests_for         :job, :jobs_013
  index_page_tests_for       :job, :jobs_014

  edit_aliases_test_for :job, :director, "Der grosse Boss"

  def setup
    @controller = JobController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

end
