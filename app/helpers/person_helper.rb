module PersonHelper
  def person_jobs
    @person.jobs.uniq.slice(0,4).collect { |job|
      link_to job.local_name(@language), :action => :filmography, :anchor => "job_" + job.id.to_s
    }.join(", ")
  end
end
