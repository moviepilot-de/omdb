# Copyright (c) 2007 Benjamin Krause, Jens Kraemer
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Rake Task to setup a fresh omdb project. Run this task once after you
# have retrieved a fresh copy via svn. This task will make sure you got all
# the required directories that are not part of the subversion. You need to
# run this task once per environment.
#
# bash$ rake omdb:setup
#
# You should not run this task in test environment, as all neccessary 
# directories for running tests are part of the subversion repository.

namespace :omdb do
  desc "setup and initialize a new omdb copy"
  task :setup => :environment do
    User.create_anonymous if User.anonymous.nil?
    
    Indexer.create_directory_structure
    puts "------------------------------------------"
    puts "I will now build a new ferret index. This"
    puts "might take a long time (up to an hour if"
    puts "you installed the live omdb data)."
    puts "Press ctrl-c now to skip this task."
    puts "You can start this task anytime by invoking"
    puts ""
    puts "bash$ rake omdb:reindex"
    puts ""
    puts "I will start in 5 seconds"
    puts "------------------------------------------"
    sleep 5
    puts "Starting..."
    Indexer.reindex    
  end

  desc 'Generate movie csv list'
  task :generate_movie_csv => :environment do
    Movie.find(:all, :conditions => "type = 'Movie' or type is NULL").each do |movie|
      line = "#{movie.id}"
      if movie.end
        line << ";#{movie.end.year}"
      else
        line << ";"
      end
      line << ";#{movie.name}"
      movie.local_aliases( Language.pick('de') ).each do |a|
        line << ";#{a.name}"
      end
      puts line
    end
  end

  desc 'export genre keywords'
  task :export_genre_keywords => :environment do
    export_file = "#{RAILS_ROOT}/public/mp_genres.csv"
    genre         = Category.find 1
    german        = Language.pick('de')
    english       = Language.pick('en')
    FasterCSV.open(export_file, "w") do |csv|
      csv << [ genre.id, 0, genre.local_name(english), genre.local_name(german), genre.abstract(german).data, genre.slug ]
      genre.all_children.each do |c|
        csv << [ c.id, c.parent_id, c.local_name(english), c.local_name(german), c.abstract(german).data, c.local_aliases(german).map(&:name).join('|') ]
      end
    end
  end


  desc "export plot keywords"
  task :export_plot_keywords => :environment do
    export_file = "#{RAILS_ROOT}/public/mp_keywords.csv"
    plot_keywords = Category.find 10032
    german        = Language.pick('de')
    english       = Language.pick('en')
    FasterCSV.open(export_file, "w") do |csv|
      csv << [ plot_keywords.id, 0, plot_keywords.local_name(english), plot_keywords.local_name(german), plot_keywords.abstract(german).data ]
      plot_keywords.all_children.each do |c|
        csv << [ c.id, c.parent_id, c.local_name(english), c.local_name(german), c.abstract(german).data, c.local_aliases(german).map(&:name).join('|') ]
      end
    end
  end

  desc "export place keywords"
  task :export_place_keywords => :environment do
    export_file = "#{RAILS_ROOT}/public/mp_place.csv"
    place         = Category.find 3669
    german        = Language.pick('de')
    english       = Language.pick('en')
    FasterCSV.open(export_file, "w") do |csv|
      csv << [ place.id, 0, place.local_name(english), place.local_name(german), place.abstract(german).data ]
      place.all_children.each do |c|
        csv << [ c.id, c.parent_id, c.local_name(english), c.local_name(german), c.abstract(german).data, c.local_aliases(german).map(&:name).join('|') ]
      end
    end
  end

  desc "export audience keywords"
  task :export_audieces => :environment do
    export_file = "#{RAILS_ROOT}/public/mp_audiences.csv"
    place         = Category.find 5
    german        = Language.pick('de')
    english       = Language.pick('en')
    FasterCSV.open(export_file, "w") do |csv|
      csv << [ place.id, 0, place.local_name(english), place.local_name(german), place.abstract(german).data ]
      place.all_children.each do |c|
        csv << [ c.id, c.parent_id, c.local_name(english), c.local_name(german), c.abstract(german).data, c.local_aliases(german).map(&:name).join('|') ]
      end
    end
  end

  desc "export time keywords"
  task :export_time_keywords => :environment do
    export_file = "#{RAILS_ROOT}/public/mp_time.csv"
    time          = Category.find 3667
    german        = Language.pick('de')
    english       = Language.pick('en')
    FasterCSV.open(export_file, "w") do |csv|
      csv << [ time.id, 0, time.local_name(english), time.local_name(german), time.abstract(german).data ]
      time.all_children.each do |c|
        csv << [ c.id, c.parent_id, c.local_name(english), c.local_name(german), c.abstract(german).data, c.local_aliases(german).map(&:name).join('|') ]
      end
    end
  end

  desc "export emotion keywords"
  task :export_emotion_keywords => :environment do
    export_file = "#{RAILS_ROOT}/public/mp_emotion.csv"
    emotion       = Category.find 10213
    german        = Language.pick('de')
    english       = Language.pick('en')
    FasterCSV.open(export_file, "w") do |csv|
      csv << [ emotion.id, 0, emotion.local_name(english), emotion.local_name(german), emotion.abstract(german).data ]
      emotion.all_children.each do |c|
        csv << [ c.id, c.parent_id, c.local_name(english), c.local_name(german), c.abstract(german).data, c.local_aliases(german).map(&:name).join('|') ]
      end
    end
  end

  desc "export movies"
  task :export_movies => :environment do
    export_directory = "/tmp/movies"
    export_archive   = "#{RAILS_ROOT}/public/mp_movies.tar.gz"
    FileUtils.rm_rf   export_directory
    FileUtils.mkdir_p export_directory
    german = Language.pick('de')
    Movie.find(:all, :conditions => "type = 'Movie' OR type is null").each do |movie|
      File.open("#{export_directory}/#{movie.id}.xml", 'w') do |out|
        xml = Builder::XmlMarkup.new( :indent => 2, :target => out )
        xml.instruct!( :xml, :encoding => "UTF-8" )
        xml.movie do |m|
          m.id              movie.id
          m.original_title  movie.name
          m.title           movie.local_name german
          m.production_year movie.production_year.to_s
          m.state           movie.status
          m.popularity      movie.popularity
          m.abstract        movie.abstract(german).data
          m.description     movie.page('index', german).data_html
          m.runtime         movie.runtime
          m.poster          movie.image.filename if movie.image and not movie.image.filename.blank?
          m.trailer         movie.trailer(german).key unless movie.trailer(german).new_record?
          m.genres do |g|
            movie.genres.each do |genre|
              g.genre genre.id
            end
          end
          m.keywords do |k|
            movie.keywords.each do |keyword|
              k.keyword keyword.id
            end
            movie.terms.each do |keyword|
              k.keyword keyword.id
            end
            movie.audiences.each do |keyword|
              k.keyword keyword.id
            end
          end
          m.crew do |crew|
            movie.crew.each do |crew_member|
              m.member( crew_member.id, :person_id => crew_member.person.id, :job_id => crew_member.job.id, :position => crew_member.position )
            end
          end
          m.cast do |cast|
            movie.casts.each do |cast_member|
              if Department.acting.children.map(&:id).include?(cast_member.job.id)
                m.member( cast_member.id, :person_id => cast_member.person.id, :job_id => cast_member.job.id, :position => cast_member.position, :name => cast_member.comment.gsub('"', "'"))
              end
            end
          end
        end
      end
    end
    FileUtils.rm export_archive if File.exists?(export_archive)
    Kernel.system "tar czf #{export_archive} #{export_directory}" 
  end

  desc "export tv series"
  task :export_series => :environment do
    export_directory = "/tmp/series"
    export_archive   = "#{RAILS_ROOT}/public/mp_series.tar.gz"
    FileUtils.rm_rf   export_directory
    FileUtils.mkdir_p export_directory
    german = Language.pick('de')
    Series.find(:all).each do |movie|
      File.open("#{export_directory}/#{movie.id}.xml", 'w') do |out|
        xml = Builder::XmlMarkup.new( :indent => 2, :target => out )
        xml.instruct!( :xml, :encoding => "UTF-8" )
        xml.series do |m|
          m.id              movie.id
          m.title           movie.local_name german
          m.original_title  movie.name
          m.series_type     movie.series_type
          m.abstract        movie.abstract(german).data
          m.description     movie.page('index', german).data_html
          m.poster          movie.image.filename if movie.image and not movie.image.filename.blank?
          m.genres do |g|
            movie.genres.each do |genre|
              g.genre genre.id
            end
          end
          m.keywords do |k|
            movie.keywords.each do |keyword|
              k.keyword keyword.id
            end
            movie.terms.each do |keyword|
              k.keyword keyword.id
            end
            movie.audiences.each do |keyword|
              k.keyword keyword.id
            end
          end
        end
      end
    end
    FileUtils.rm export_archive if File.exists?(export_archive)
    Kernel.system "tar czf #{export_archive} #{export_directory}" 
  end
  
  
  desc 'export tv seasons'
  task :export_seasons => :environment do
    export_directory = "/tmp/seasons"
    export_archive   = "#{RAILS_ROOT}/public/mp_seasons.tar.gz"
    FileUtils.rm_rf   export_directory
    FileUtils.mkdir_p export_directory
    german = Language.pick('de')
    Season.find(:all).each do |movie|
      File.open("#{export_directory}/#{movie.id}.xml", 'w') do |out|
        xml = Builder::XmlMarkup.new( :indent => 2, :target => out )
        xml.instruct!( :xml, :encoding => "UTF-8" )
        xml.season do |m|
          m.id              movie.id
          m.series          movie.parent.id
          m.title           movie.local_name german
          m.original_title  movie.name
          m.season_type     movie.season_type
          m.abstract        movie.abstract(german).data
          m.description     movie.page('index', german).data_html
          m.poster          movie.image.filename if movie.image and not movie.image.filename.blank?
        end
      end
    end
    FileUtils.rm export_archive if File.exists?(export_archive)
    Kernel.system "tar czf #{export_archive} #{export_directory}" 
  end


  desc 'Generate people csv list'
  task :generate_people_csv => :environment do
    require 'fastercsv'
    FasterCSV.open("#{RAILS_ROOT}/public/mp_people.csv", "w") do |csv|
      Person.find(:all).each do |person|
        image_url = person.portrait.nil? ? '' : person.portrait.filename
        csv << [ person.id, person.name.strip, person.birthday, person.deathday, person.homepage, image_url, person.abstract(Language.pick('de')).data, person.abstract(Language.pick('en')).data, person.page('index', Language.pick('de')).data_html, person.page('index', Language.pick('en')).data_html ]
      end
    end
  end

  desc 'Reindex Jobs and Categories'
  task :update_index => :environment do
    [ Job, Category, Country, Company ].each do |klass|
      klass.find(:all).each do |o|
        Indexer.index_object o.to_hash_args
      end
    end
  end

  desc 'Reindex almost everything'
  task :update_index_daily => :environment do
    [ Job, Category, Country, Movie, Person ].each do |klass|
      klass.find(:all).each do |o|
        Indexer.index_object o.to_hash_args
      end
    end
  end
end
