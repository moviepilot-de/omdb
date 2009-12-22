require File.dirname(__FILE__) + '/../test_helper'

class MultiFilterTest < Test::Unit::TestCase
  include Ferret::Search
  include Ferret::Index
  def setup
    field_infos = FieldInfos.new(:store => :no, :term_vector => :no)
    field_infos.add_field(:published, :index => :untokenized)
    @index = Ferret::I.new(:field_infos => field_infos)
    [
      {:published => 'yes', :date => "20060101"},
      {:published => 'no',  :date => "20060102"},
      {:published => 'yes', :date => "20060103"},
      {:published => 'no',  :date => "20060104"},
      {:published => 'yes', :date => "20060105"},
      {:published => 'no',  :date => "20060106"},
      {:published => 'yes', :date => "20060107"},
      {:published => 'no',  :date => "20060108"},
      {:published => 'yes', :date => "20060109"},
      {:published => 'no',  :date => "20060110"},
    ].each {|doc| @index << doc}
  end

  def teardown
    @index.close
  end

  def test_empty_multi_filter
    assert_equal 10, @index.search("*", :filter => MultiFilter.new).total_hits
  end

  def do_test_multi_filter(expected, multi_filter)
    ids = @index.search("*", :filter => multi_filter).hits.collect {|h| h.doc}
    assert_equal expected, ids
  end

  include Ferret::Utils
  def test_multi_filter
    mf = MultiFilter.new
    mf[:published] = QueryFilter.new(TermQuery.new(:published, "yes"))
    do_test_multi_filter [0, 2, 4, 6, 8],  mf

    mf[:date] = RangeFilter.new(:date, :>= => "20060102", :< => "20060109")
    do_test_multi_filter [2, 4, 6], mf

    mf[:date] = RangeFilter.new(:date, :>= => "20060100", :< => "20060109")
    do_test_multi_filter [0, 2, 4, 6], mf

    mf[:published] = QueryFilter.new(TermQuery.new(:published, "no"))
    do_test_multi_filter [1, 3, 5, 7], mf

    mf.delete(:published)
    do_test_multi_filter [0, 1, 2, 3, 4, 5, 6, 7], mf
  end
end
