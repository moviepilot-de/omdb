require File.dirname(__FILE__) + '/../test_helper'

class UniqueQueueTest < Test::Unit::TestCase

  def setup
    @queue = UniqueQueue.new
  end

  def teardown
    @queue = nil
  end

  def test_empty_and_size
    assert @queue.empty?
    @queue.enq 'test'
    assert !@queue.empty?
    assert_equal 1, @queue.size
    @queue.deq
    assert @queue.empty?
    assert_equal 0, @queue.size
  end

  def test_enq_deq
    ary = [ 'ClassA', 123, :action ]
    @queue.enq ary
    assert_equal 1, @queue.size
    assert_equal ary, @queue.deq
    assert_equal 0, @queue.size
  end

  def test_clear
    assert Queue === @queue
    @queue.clear
    assert @queue.enq('test')
    assert !@queue.empty?
    @queue.clear
    assert @queue.empty?
    assert @queue.enq('test')
    assert !@queue.empty?
  end

  # arrays with equal contents are treated as equal by Set
  def test_uniqueness_array
    ary = [ 'ClassA', 123, :action ]
    assert @queue.enq(ary.dup)
    assert !@queue.enq(ary.dup)
    assert_equal 1, @queue.size
    assert_equal ary, @queue.deq
    assert_equal 0, @queue.size
  end
  
  # strings are, too.
  def test_uniqueness_string
    assert (@queue << 'string')
    assert_equal 1, @queue.size
    assert !(@queue << 'string')
    assert_equal 1, @queue.size
    assert_equal 'string', @queue.pop
    assert_equal 0, @queue.size
  end

  # hashes aren't
  def test_custom_comparable_impl
    @queue = UniqueQueue.new
    hash = { :a => 'a' }
    assert @queue.enq(hash)
    assert @queue.enq(hash.dup)
    assert_equal 2, @queue.size


    @queue = UniqueQueue.new(lambda { |obj| obj.inspect })
    assert @queue.enq(hash)
    assert !@queue.enq(hash.dup)
    assert_equal 1, @queue.size
    assert_equal hash, @queue.deq
    assert @queue.empty?
  end

end

