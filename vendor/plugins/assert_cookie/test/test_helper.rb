require 'test/unit'
require 'test/unit/assertions'
require 'cgi'
require 'time'
require 'assert_cookie'

# This stub for +clean_backtrace+ is included for testing
# because I cannot figure out how to require the version that
# Rails provides. Help me fix this.
module Test
  module Unit
    module Assertions
      def clean_backtrace; yield  end
    end
    
    class TestCase
    protected
      def assert_pass
        assert_block("assert_pass must be called with a block.") { block_given? }
        yield
      end

      def assert_fail
        assert_block("assert_fail must be called with a block.") { block_given? }
        yield
      rescue AssertionFailedError
      end
    end
  end
end

