task :calculate_review_counts => :environment do
  movies = Movie.find(:all)

  movies.each do |m|
    m.reviews.reload
    m.reviews_count = m.reviews.size
    m.save
  end
end
