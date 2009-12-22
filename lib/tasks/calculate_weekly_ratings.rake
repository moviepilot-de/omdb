desc "Generate Popularity and Voting Statistics on a weekly basis"
task :stats_calc => :environment do
    RatingHistory.delete_all
    
    1.upto(52) do |i|
      PopularityHistory.generate_report(2006, i)
    end

    1.upto(52) do |i|
      VoteHistory.generate_report(2006, i)      
    end

end
