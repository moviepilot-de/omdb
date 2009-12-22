require File.dirname(__FILE__) + '/string/unicode'

class String #:nodoc:
  include ActiveSupport::CoreExtensions::String::Unicode
end
