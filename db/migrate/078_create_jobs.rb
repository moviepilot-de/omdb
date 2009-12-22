class CreateJobs < ActiveRecord::Migration
  def self.up
    create_table :jobs do |t|
      t.column "parent_id", :integer
      t.column "type", :string, :limit => 12
      t.column "default_job_id", :integer
    end
    add_column :casts, :job_id, :integer, :null => false
    add_column :name_aliases, :job_id, :integer, :null => false
    add_column :name_alias_versions, :job_id, :integer, :null => false
    add_column :contents, :job_id, :integer, :null => false
    add_column :content_versions, :job_id, :integer, :null => false
    add_column :images, :job_id, :integer, :null => false
    add_index :casts, [:movie_id, :job_id], :name => "casts_movie_and_job_index"
    add_index :casts, [:person_id, :job_id], :name => "casts_person_and_job_index"
    add_index :name_aliases, :job_id
    add_index :contents, :job_id
    add_index :images, :job_id
    add_index :jobs, :parent_id
    add_index :jobs, :type

    Department.initialize
  end

  def self.down
    drop_table :jobs

    remove_column :casts, :job_id
    remove_column :name_aliases, :job_id
    remove_column :name_alias_versions, :job_id
    remove_column :contents, :job_id
    remove_column :content_versions, :job_id
    remove_column :images, :job_id
    remove_index :casts, "movie_and_job"
    remove_index :casts, "person_and_job"
  end
end
