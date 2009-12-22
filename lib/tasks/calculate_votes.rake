task :calculate_votes => :environment do
  movies = Movie.find(:all)

  movies.each do |m|
    m.votes.reload
    m.votes_count = m.votes.size
    m.save
  end
end
