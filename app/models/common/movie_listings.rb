module MovieListings
  def top_movies
    popular_movies.delete_if { |m|
      last_movies.include?(m)
    }.slice(0,5)
  end

  def last_movies
    chronological_movies.reverse.slice(0,3)
  end
end
