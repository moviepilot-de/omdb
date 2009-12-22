class ConvertCasts < ActiveRecord::Migration
  def self.up
    jobs = {}

    Actor.find_all.each { |a|
      a.job = Job.find( 15 )
      a.save
    }

    { Author => 13, Casting => 17, Cinematographer => 23, Director => 21, Producer => 16,
      Composer => 27, Crew => 12, Editor => 33, ProductionDesigner => 18, SoundDesigner => 19 }.each { |klass, job_id|
      jobs[klass.to_s.downcase] = job_id
      klass.find_all.each { |c|
        default_job = Job.find( job_id )
        c.type = "Cast"
        if c.comment.strip != "" 
          if jobs.has_key?( c.comment.strip.downcase )
            c.job = Job.find( jobs[c.comment.strip.downcase] )
          else
            job = Job.new
            job.parent = default_job.department
            job.aliases << NameAlias.new( :name     => c.comment.strip, 
                                          :language => Locale.base_language, 
                                          :job      => job )
            job.save
            jobs[ c.comment.strip.downcase ] = job.id
            c.job = job
          end
        else
          c.job = default_job
        end
        c.comment = ""
        c.save
      }
    }
  end

  def self.down
  end
end
