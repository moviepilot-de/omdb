class MakeNameAliasesPolymorphic < ActiveRecord::Migration

  NAME_ALIAS_CLASSES = [ :category, :character, :company, :country, 
                      :image, :job, :movie, :person, :actor, :image ]

  def self.up
    add_column "name_aliases", "related_object_type", :string
    add_column "name_aliases", "related_object_id", :integer
    ActiveRecord::Migration.execute "UPDATE name_aliases SET related_object_type = alias_type"
    NAME_ALIAS_CLASSES.each do |sym|
      ActiveRecord::Migration.execute "UPDATE name_aliases SET related_object_id=#{sym.to_s}_id WHERE related_object_type = '#{sym.to_s}'"
    end
    #sonderfälle:
    ActiveRecord::Migration.execute "UPDATE name_aliases SET related_object_id = movie_id WHERE related_object_type = 'MovieSeries'"
    ActiveRecord::Migration.execute "UPDATE name_aliases SET related_object_id = movie_id WHERE related_object_type = 'Episode'"
    ActiveRecord::Migration.execute "UPDATE name_aliases SET related_object_id = movie_id WHERE related_object_type = 'ShortMovie'"
    ActiveRecord::Migration.execute "UPDATE name_aliases SET related_object_id = movie_id WHERE related_object_type = 'Series'"
    ActiveRecord::Migration.execute "UPDATE name_aliases SET related_object_id = job_id WHERE related_object_type = 'Department'"
    ActiveRecord::Migration.execute "UPDATE name_aliases SET related_object_id = country_id WHERE related_object_type = 'Globalize::Country'"    
  
    ActiveRecord::Migration.execute "UPDATE name_aliases SET related_object_type = 'Job' WHERE related_object_type = 'Department'"
    ActiveRecord::Migration.execute "UPDATE name_aliases SET related_object_type = 'Movie' WHERE (related_object_type = 'MovieSeries' OR related_object_type = 'Episode' OR related_object_type = 'ShortMovie' OR related_object_type = 'Series')"
    
  end

  def self.down
    remove_column "name_aliases", "related_object_type"
    remove_column "name_aliases", "related_object_id"
  end
end
