module OMDB
  module Ferret
    module SimilarMovies
      
      def find_similar_movies( movie )
        categories        = ::Ferret::Search::MultiTermQuery.new :category_ids, :max_terms => 256
        lesser_categories = ::Ferret::Search::MultiTermQuery.new :category_ids, :max_terms => 256
        keywords          = ::Ferret::Search::MultiTermQuery.new :keyword_ids, :max_terms => 256
        lesser_keywords   = ::Ferret::Search::MultiTermQuery.new :category_ids, :max_terms => 256
        people            = ::Ferret::Search::MultiTermQuery.new :person_ids, :max_terms => 256

        # rank the subqueries
        categories.boost        = 20
        lesser_categories.boost = 12
        keywords.boost          = 10
        lesser_keywords.boost   = 4
        people.boost            = 1

        [ :genres, :audiences, :productions, :standings, :epoches ].each do |method|
          movie.send( method ).each do |g| 
            categories << g.id.to_s
            # add parent elements to the query
            g.ancestors[0..-2].each do |p|
              lesser_categories << p.id.to_s
            end
          end
        end
        [ :keywords ].each do |method|
          movie.send( method ).each do |g| 
            keywords << g.id.to_s
            g.ancestors[0..-2].each do |p|
              lesser_keywords << p.id.to_s
            end            
          end
        end
        [ :authors, :directors, :producers, :actors ].each do |method|
          movie.send( method ).each { |cast| people << cast.person.id.to_s }          
        end
        query = ::Ferret::Search::BooleanQuery.new
        query.add_query categories
        query.add_query lesser_categories
        query.add_query keywords
        query.add_query lesser_keywords
        query.add_query people
        query.add_query ::Ferret::Search::TermQuery.new( :movie_type, movie.class.to_s.demodulize.underscore )
        query.add_query( ::Ferret::Search::TermQuery.new( :object_id, movie.id.to_s), :must_not )
        self.do_search( query, 5 )
        # self.explain( query, { :limit => 2 } )
      end
      
    end
  end
end