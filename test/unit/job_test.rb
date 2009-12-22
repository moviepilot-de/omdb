require File.dirname(__FILE__) + '/../test_helper'

class JobTest < Test::Unit::TestCase
  fixtures :jobs, :movies, :people, :name_aliases

  # Test for correct flattened name
  def test_flattened_name
    job = Job.actor
    assert_equal "Acting > Actor", job.flattened_name( Locale.base_language )
  end

  # Only Departments must have parent = nil
  def test_require_parent
    job = Job.director
    job.parent = nil
    assert_raise(ActiveRecord::RecordInvalid) { job.save! }
  end

end
