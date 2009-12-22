require File.dirname(__FILE__) + '/../test_helper'

class StringTest < Test::Unit::TestCase
  
  # see the extended String#pluralize in lib/omdb/strings.rb
  def test_pluralize
    # original behaviour
    assert_equal 'Trees', 'Tree'.pluralize 
    # extension: pluralize accoring to given count, but without prepending the
    # count itself the string
    assert_equal 'Trees', 'Tree'.pluralize(0)
    assert_equal 'Trees', 'Tree'.pluralize(9)
    assert_equal 'Tree', 'Tree'.pluralize(1)
  end
end
