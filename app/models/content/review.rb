class Review < Content

  #validates_uniqueness_of :user_id, :scope => [ :movie_id ]

  def vote(movie, user_id)
    v = movie.votes.find_by_user_id user_id
    return v.vote unless v.nil?
  end
  

  def self.score_text(score, reverse=false)
    if reverse
      text = {10 => "Nothing", 9 => "Abysmal", 8 => "Sucks", 7 => "Bad", 6=> "Poor", 5 => "Mediocre", 4 => "Fair", 3 => "Good", 2 => "Great", 1 => "Superb", 0 => "Perfect"}
    else
      text = {0 => "Nothing", 1 => "Abysmal", 2 => "Sucks", 3 => "Bad", 4=> "Poor", 5 => "Mediocre", 6 => "Fair", 7 => "Good", 8 => "Great", 9 => "Superb", 10 => "Perfect"}
    end
    return text[score.abs.to_i]
  end

end
