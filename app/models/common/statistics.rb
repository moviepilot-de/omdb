module Statistics
  def movies_per_year
    movies = all_movies 99999, 0
    movies_by_year = build_movies_by_year_hash movies
    labels = build_labels movies
    data = []
    first_year, last_year = get_years( movies )

    (first_year..last_year).each_with_index do |year, counter|
      if movies_by_year.has_key?(year)
        data.push movies_by_year[year].size
      else
        data.push nil
      end
    end
    [ data, labels ]
  end

  def quality_per_year
    movies = all_movies 99999, 0
    movies_by_year = build_movies_by_year_hash movies
    labels = build_labels movies
    first_year, last_year = get_years( movies )
    data = []
    (first_year..last_year).each_with_index do |year, counter|
      if movies_by_year.has_key?(year)
        vote = 0
        movies_by_year[year].each {|m|
                vote = vote + m.vote
              }
        data.push( vote / movies_by_year[year].size )
      else
        data.push nil
      end
    end
    [ data, labels ]
  end
    
  def movie_by_rating
    ratings = Array.new
    i = 1
    1.upto(10) do
      ratings.push( Vote.count(:all, :conditions => ['movie_id = ? and vote = ?', self.id, i]) )
      i += 1
    end
    return ratings
  end
    
  def movie_by_rating_percentage
    rating_count = Vote.count(:all, :conditions => ['movie_id = ?', self.id])
    ratings = Array.new
    i = 1
    1.upto(10) do
      ratings.push( Vote.count(:all, :conditions => ['movie_id = ? and vote = ?', self.id, i]).to_f / rating_count )
      i += 1
    end
    return ratings
  end
    
  def movie_rating_by_gender(gender)
    rating_count = Vote.count(:all, :include => :user, :conditions => ['movie_id = ? and users.gender = ?', self.id, gender] )
    ratings = Array.new
    i = 1
    1.upto(10) do
      ratings.push( Vote.count(:all, :include => :user, :conditions => ['movie_id = ? and vote = ? and users.gender = ?', self.id, i, gender]).to_f / rating_count )
      i += 1
    end
    return ratings
  end
    
    def movie_rating_by_country(country)
      rating_count = Vote.count(:all, :include => :user, :conditions => ['movie_id = ? and users.country_id = ?', self.id, country] )
      ratings = Array.new
      i = 1
      1.upto(10) do
        ratings.push( Vote.count(:all, :include => :user, :conditions => ['movie_id = ? and vote = ? and users.country_id = ?', self.id, i, country]).to_f / rating_count )
        i += 1
      end
      return ratings
    end

    def movie_rating_by_continent(continent)
      case continent
        when 'europe': country_list = Country.european_country_ids
        #when us I'll just take the US ID
        when 'us': country_list = Array.[](223)
        else
          raise 'Not allowed continent'
      end
      rating_count = Vote.count(:all, :include => :user, :conditions => ['movie_id = ? and users.country_id in (?)', self.id, country_list] )
      ratings = Array.new
      i = 1
      1.upto(10) do
        ratings.push( Vote.count(:all, :include => :user, :conditions => ['movie_id = ? and vote = ? and users.country_id in (?)', self.id, i, country_list]).to_f / rating_count )
        i += 1
      end
      return ratings
    end
    
    def movie_votes_per_week( start_week=nil, end_week=nil, year=nil )
      ratings = Array.new
      labels = Hash.new
      i = 0
      start_week.upto(end_week) do |week|
        d = Date.commercial(year,week)
        v = VoteHistory.find(:first, :conditions => ['related_object_id = ? and related_object_type = ? and start_date = ?', self.id, self.class.base_class.to_s, d])
        ratings.push( v.nil? ? ( (start_week == week) ? 0 : ratings[ratings.size-1] ) : v.rating )
        labels[i] = week.to_s if i.odd?
        i += 1
      end
      return [ ratings, labels ]
    end
    
    def movie_popularity_per_week( start_week=nil, end_week=nil, year=nil )
      ratings = Array.new
      labels = Hash.new
      i = 0
      start_week.upto(end_week) do |week|
        d = Date.commercial(year,week)
        v = PopularityHistory.find(:first, :conditions => ['related_object_id = ? and related_object_type = ? and start_date = ?', self.id, self.class.base_class.to_s, d])
        ratings.push( v.nil? ? ( (start_week == week) ? 0 : ratings[ratings.size-1] ) : (1001 - v.rating * (1000*(v.rating+80)**-1.2) ) )
        labels[i] = week.to_s if i.odd?
        i += 1
      end
      return [ ratings, labels ]
    end
    

  private

  def build_movies_by_year_hash( movies )
    movie_by_year = {}
    movies.each { |m|
      next if m.end.nil?
      movie_by_year[m.end.year] = movie_by_year[m.end.year] ||= []
      movie_by_year[m.end.year].push(m)
    }
    movie_by_year
  end

  def build_labels( movies )
    labels = {}
    first_year, last_year = get_years( movies )
    years = last_year - first_year
    modulo = (years < 20) ? 5 : ((years < 50) ? 10 : 20)
    (first_year..last_year).each_with_index { |year, counter|
      labels[counter] = year.to_s if (year % modulo == 0) or counter == 0
    }
    labels
  end

  def get_years( movies )
    first_year = 1900
    last_year = Time.now.year
    movies.each do |m|
      if not m.end.nil?
        first_year = m.end.year          
        break
      end
    end
    movies.reverse.each do |m|
      if not m.end.nil?
        last_year = m.end.year
        break
      end
    end
    [ first_year, last_year ]
  end
end
