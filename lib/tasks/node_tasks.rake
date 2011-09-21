
namespace :node do
  desc 'export genre keywords'
  task :export_categories => :environment do
    export_file = "#{RAILS_ROOT}/public/node_categories.csv"
    genre         = Category.find 1
    emotion       = Category.find 10213
    german        = Language.pick('de')
    english       = Language.pick('en')
    FasterCSV.open(export_file, "w") do |csv|
      csv << %w(id _classname name)
      Category.find(:all).each do |c|
        csv << [ c.id+4_000_000, c.base_name.camelize, c.local_name(english) ]
      end
    end
  end

  desc 'export category relations'
  task :export_category_relations => :environment do
    export_file = "#{RAILS_ROOT}/public/node_category_relations.csv"
    FasterCSV.open(export_file, "w") do |csv|
      csv << %w(id source_id target_id)
      Category.find(:all).each do |c|
        next if c.parent.nil? or c.parent_id == 1000
        csv << [ 0, c.parent_id+4_000_000, c.id+4_000_000 ]
      end
    end
  end

  desc 'export movie category relations'
  task :export_movie_category_relations => :environment do
    export_file = "#{RAILS_ROOT}/public/node_movoe_category_relations.csv"
    FasterCSV.open(export_file, "w") do |csv|
      csv << %w(id source_id target_id)
      MovieUserCategory.find(:all).each do |muc|
        csv << [ 0, muc.movie.id, muc.category.id ]
      end
    end
  end
  
end
