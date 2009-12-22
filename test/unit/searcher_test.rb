require File.dirname(__FILE__) + '/../test_helper'

class SearcherTest < Test::Unit::TestCase

  def setup
  end

  def test_filter_special_characters
    assert_equal 'abc', Searcher.filter_special_characters('a>b>c')
  end

end
