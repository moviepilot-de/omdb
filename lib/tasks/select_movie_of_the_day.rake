task :select_movie_of_the_day => :environment do
  now = Date.jd(DateTime.now.jd)
  one_year_ago = now - 365
  
  looping = true
  
  while looping do
    movie = Movie.find_by_sql("select * from movies where (vote > 6) and (type = 'Movie') and (movie_of_the_day < '#{one_year_ago.to_s}' or movie_of_the_day is NULL)  order by rand() limit 1;").first
    unless movie.abstract( Language.pick 'de' ).data.empty?
      movie.movie_of_the_day = now
      movie.save
      looping = false
    end
  end
  Movie.find(4536).update_attribute :popularity, 0
end

task :select_person_of_the_day => :environment do
  now = Date.jd(DateTime.now.jd)
  one_year_ago = now - 365
  looping = true
  
  while looping do
    person = Person.person_of_the_day_candidate
    unless person.abstract( Language.pick 'de' ).data.empty?
      person.person_of_the_day = now
      person.save
      looping = false
    end
  end

end
