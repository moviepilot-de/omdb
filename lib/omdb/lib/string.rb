class String
  alias :original_pluralize :pluralize
  def pluralize(count = nil)
    return original_pluralize unless count && count == 1
    self
  end
end
