class CastLogEntry < LogEntry

  def value
    old_value.nil? ? new_value : old_value
  end

  def job
    Job.find value.split(',').last
  end

  def person
    Person.find value.split(',').first
  end
end
