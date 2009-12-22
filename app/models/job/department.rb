class Department < Job

  if not defined?(DEPARTMENT_TYPES)
    DEPARTMENT_TYPES = ["Writing", "Production", "Directing", "Acting", "Camera", "Lightning", 
                        "Sound", "Art", "Costume", "Editing", "VisualEffects", "Crew"]
  end

  belongs_to :default_job,
             :foreign_key => "default_job_id",
             :class_name => "Job"

  DEPARTMENT_TYPES.each_with_index { |type, index|
    (class << Department; self; end).class_eval {
      body = lambda { 
        class_variables.include?("@@#{type.underscore}") ? 
            class_variable_get("@@#{type.underscore}") : 
            class_variable_set("@@#{type.underscore}", Department.find(index + 1))
      }
      define_method( "#{type.underscore}", body )
     }
  }

  def self.initialize
    Job.destroy_all
    self.reset_auto_increment
    DEPARTMENT_TYPES.each { |t|
      dep = Department.create()
      dep.aliases.create(:name => t, :language => Locale.base_language)
    }
    create_job Department.writing, "Author"
    create_default_job Department.writing, "Other"
    create_default_job Department.acting, "Actor"
    create_job Department.production, "Producer"
    create_job Department.production, "Casting"
    create_job Department.production, "Production Design"
    create_job Department.production, "Sound Design"
    create_default_job Department.production, "Other"
    create_job Department.directing, "Director"
    create_default_job Department.directing, "Other"
    create_job Department.camera, "Director of Photography"
    create_default_job Department.camera, "Other"
    create_job Department.lightning, "Gaffer"
    create_default_job Department.lightning, "Other"
    create_job Department.sound, "Composer"
    create_default_job Department.sound, "Other"
    create_job Department.art, "Set Designer"
    create_default_job Department.art, "Other"
    create_job Department.costume, "Costume Designer"
    create_default_job Department.costume, "Other"
    create_job Department.editing, "Editor"
    create_default_job Department.editing, "Other"
    create_job Department.visual_effects, "Visual Effects Supervisor"
    create_default_job Department.visual_effects, "Other"
    create_job Department.crew, "Continuity"
    create_default_job Department.crew, "Other"
  end

  def self.departments
    find(:all)
  end

  def self.create_job( department, name )
    job = Job.new( :parent => department )
    job.aliases.create( :name => name, :language => Locale.base_language )
    job.save
    job
  end

  def self.create_default_job( department, name )
    department.default_job_id = self.create_job( department, name ).id
    department.save
  end

end
