class VoteHistory < RatingHistory
  
  def self.generate_report(year, week)
    start_date = DateTime.commercial(year,week)
    #I'm catching the case when the week is in the new year
    end_date = DateTime.commercial(year,week+1) rescue DateTime.commercial(year+1,1)

  
    movies = Movie.find_by_sql ["select movie_id as id, (sum(vote) / count(*)) as voting from votes where created_at > ? and created_at < ? group by movie_id", start_date, end_date ]

    movies.each do |m|
      stat = self.new
      stat.related_object = m
      stat.rating = m.voting
      stat.start_date = start_date
      stat.end_date = end_date
      #get the STI Classname when called as a Class Method
      stat.type = self.to_s
      stat.save
    end
  end
  
end