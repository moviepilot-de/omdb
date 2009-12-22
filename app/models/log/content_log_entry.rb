class ContentLogEntry < LogEntry
  validates_numericality_of :attribute

  def content
    @content ||= Content.find attribute.to_i
  end
end
