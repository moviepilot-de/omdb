require "config/environment.rb"

   export_directory = "/tmp/movies"
    export_archive   = "#{RAILS_ROOT}/public/mp_movies.tar.gz"
    FileUtils.rm_rf   export_directory
    FileUtils.mkdir_p export_directory
    german = Language.pick('de')

		movie = Movie.find 49404

    id = 0

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

puts "feddich!"
