require 'ferret_paginator'

module OMDB
  module Ferret
    module LocalSearch
      include ::Ferret
      include ::Ferret::Search
      include ::Ferret::Search::Spans

      FERRET_SPECIAL_CHARS = [ /:/, /\(/, /\)/, /\[/, /\]/, /!/, /\+/, /"/, /~/, /\^/, 
                               /-/, /|/, />/, /</, /=/, /\*/, /\?/, /\./, /&/ ] unless defined?( FERRET_SPECIAL_CHARS )
  
      # Popular result queries
      DIRECT_HIT_QUERY = '(name:"%s") OR (name_%s:"%s")'                       unless defined?( DIRECT_HIT_QUERY )

      DEFAULT_LANG = Locale.base_language.code unless defined?( DEFAULT_LANG )

      def direct_hits( q, lang = DEFAULT_LANG )
        q = filter_special_characters( q )
        query  = "name:\"#{q}\" OR name_en:\"#{q}\""
        query << " OR name_#{lang}:\"#{q}\"" unless lang == DEFAULT_LANG
        query << " OR aliases_#{lang}:\"#{q}\"" unless lang == DEFAULT_LANG
        objects = self.do_search query, 10
      end


      # == Basic Searches 
      # these searches are needed for the /search result pages
      
      DEFAULT_QUERY = '(%s) AND (type:movie OR type:person OR type:character OR type:category)' unless defined?( DEFAULT_QUERY )
      MOVIE_QUERY = "type:movie AND name|aliases_%s:%s" unless defined?( MOVIE_QUERY )
      PERSON_QUERY = "type:person AND name|aliases: %s" unless defined?( PERSON_QUERY )
      ENCYCLOPEDIA_QUERY = '(%s) AND (type:character OR type:category OR type:job OR type:company)' unless defined?( ENCYCLOPEDIA_QUERY )

      def search( q, lang = DEFAULT_LANG, page = 1 )
        query = build_default_query(q, lang)
        FerretPaginator.find_paginated( :query => query, :page_size => 24, :current => page, :language => lang, :hits => self.hit_count(query) )
      end

      def search_movies( q, lang = DEFAULT_LANG, page = 1 )
        return [] if q.strip.empty?
        query = sprintf( MOVIE_QUERY, lang, build_fuzzy_query(q) )
        order = orderfield [:popularity], :reverse => true, :type => :float
        FerretPaginator.find_paginated( :query => query, :page_size => 24, :current => page, :language => lang, :hits => self.hit_count(query), :order => order )
      end

      def search_people( q, lang = DEFAULT_LANG, page = 1 )
        query = sprintf( PERSON_QUERY, build_fuzzy_query(q) )
        order = orderfield( [ :name ] )
        FerretPaginator.find_paginated( :query => query, :page_size => 24, :current => page, :language => lang, :hits => self.hit_count(query), :order => order )
      end

      def search_encyclopedia( q, lang = DEFAULT_LANG, page = 1 )
        query = sprintf( ENCYCLOPEDIA_QUERY, filter_special_characters( q ) )
        FerretPaginator.find_paginated( :query => query, :page_size => 24, :current => page, :language => lang, :hits => self.hit_count(query) )
      end


      
      

      # Search for movies

      def search_filtered_movies( q, filter, lang = DEFAULT_LANG )
        return [] if q.strip.empty?
        query = "type:movie AND name|aliases_#{lang}:" + q 
        order = orderfield( [:popularity], :reverse => true, :type => :float )
        self.do_search( query, 25, 0, order, filter )
      end

      def search_movies_by_prefix( q, lang = DEFAULT_LANG )
        query = BooleanQuery.new
        query.add_query( self.build_livesearch_query( [:name, "aliases_#{lang}".to_sym], q ), :must )
        query.add_query( TermQuery.new( :type, Movie.to_s.downcase ), :must )
        order = orderfield( [ :name ] )
        self.do_search( query, 25, 0, order )
      end

      def search_good_children( movie, q, lang = DEFAULT_LANG )
        query = BooleanQuery.new
        query.add_query( self.build_livesearch_query( [:name, "aliases_#{lang}".to_sym], q ), :must )
        query.add_query( TermQuery.new( :type, Movie.to_s.downcase ), :must )
        query.add_query( TermQuery.new( :parent, 'false' ), :must )
        subq = BooleanQuery.new
        movie.class.valid_children.each do |klass|
          subq.add_query( TermQuery.new( :movie_type, klass.to_s.underscore ), :should )
        end
        query.add_query( subq, :must )
        self.do_search( query, 25, 0 )
      end

      def search_good_parents( movie, q, lang )
        if movie.class == Episode
          return self.search_good_parents_for_episodes( movie, q, lang )
        else
          query = BooleanQuery.new
          query.add_query( self.build_livesearch_query( [:name, "aliases_#{lang}".to_sym], q ), :must )
          query.add_query( TermQuery.new( :type, Movie.to_s.downcase ), :must )
          subq = BooleanQuery.new
          movie.class.valid_parents.each do |klass|
            subq.add_query( TermQuery.new( :movie_type, klass.to_s.underscore ) )
          end
          query.add_query( subq, :must )
        end
        self.do_search( query, 25, 0 )
      end


  # Search for People
  
  def search_people_by_prefix( q, lang = DEFAULT_LANG, offset = 0, limit = 100 )
    query = BooleanQuery.new
    query.add_query( self.build_livesearch_query( [:name, :aliases], q ), :must )
    query.add_query( TermQuery.new( :type, Person.to_s.downcase ), :must )
    order = orderfield( [ :popularity ], :reverse => true, :type => :float )
    self.do_search( query, limit, offset, order )
  end


  # Search for Companies

  def search_companies_by_prefix( q, lang = DEFAULT_LANG )
    query = BooleanQuery.new
    query.add_query( self.build_livesearch_query( [:name, :aliases], q ), :must )
    query.add_query( TermQuery.new( :type, Company.to_s.downcase ), :must )
    order = orderfield( [ :name ] )
    self.do_search( query, 25, 0, order )
  end


  # Search encyclopedia


  # Search for Categories and Plot-Keywords

  def search_categories( q, lang = DEFAULT_LANG, offset = 0, limit = 100 )
    query = BooleanQuery.new
    query.add_query( self.build_livesearch_query( ["keywords_#{lang}".to_sym, :keywords_en, "aliases_#{lang}".to_sym], q ), :must )
    query.add_query( TermQuery.new( :type, Category.to_s.downcase ), :must )
    order = orderfield( [ "hierarchy_#{lang}".to_sym ] )
    objects = self.do_search query, limit, offset, order
  end

  def search_categories_by_prefix( q, lang = DEFAULT_LANG, offset = 0, limit = 100 )
    query = BooleanQuery.new
    query.add_query( self.build_livesearch_query( ["keywords_#{lang}".to_sym, :keywords_en, "aliases_#{lang}".to_sym], q ), :must )
    query.add_query( TermQuery.new( :type, Category.to_s.downcase ), :must )
    query.add_query( TermQuery.new( :is_keyword, '1' ), :must_not )
    query.add_query( TermQuery.new( :is_assignable, '1' ), :must )
    order = orderfield( [ "hierarchy_#{lang}".to_sym ] )
    objects = self.do_search query, limit, offset, order
  end

  def search_keywords_by_prefix( q, lang = DEFAULT_LANG, offset = 0, limit = 100 )
    query = BooleanQuery.new
    query.add_query( self.build_livesearch_query( ["keywords_#{lang}".to_sym, :keywords_en, "aliases_#{lang}".to_sym], q ), :must )
    query.add_query( TermQuery.new( :type, Category.to_s.downcase ), :must )
    query.add_query( TermQuery.new( :is_keyword, '1' ), :must )
    query.add_query( TermQuery.new( :is_assignable, '1' ), :must )
    order = orderfield( [ "hierarchy_#{lang}".to_sym ] )
    objects = self.do_search query, limit, offset, order
  end

  def search_categories_by_type( root_id, q, lang = DEFAULT_LANG, offset = 0, limit = 100 )
    query = BooleanQuery.new
    query.add_query( self.build_livesearch_query( ["keywords_#{lang}".to_sym, :keywords_en, "aliases_#{lang}".to_sym], q ), :must )
    query.add_query( TermQuery.new( :type, Category.to_s.downcase ), :must )
    query.add_query( TermQuery.new( :root_id, root_id.to_s ), :must )
    query.add_query( TermQuery.new( :is_assignable, '1' ), :must )
    order = orderfield( [ "hierarchy_#{lang}".to_sym ] )
    objects = self.do_search query, limit, offset, order
  end
  
  def popular_categories_by_type( root_id )
    query = BooleanQuery.new
    query.add_query( TermQuery.new( :type, Category.to_s.downcase ), :must )
    query.add_query( TermQuery.new( :root_id, root_id.to_s ), :must )
    query.add_query( TermQuery.new( :is_assignable, '1' ), :must )
    order = orderfield( [ "popularity".to_sym ], :type => :integer, :reverse => true )
    objects = self.real_search( query, :limit => 30, :order => order )
  end

  # Search for Jobs

  def search_job( q, lang = DEFAULT_LANG )
    query = BooleanQuery.new
    query.add_query( self.build_livesearch_query( ["aliases_#{lang}".to_sym, :aliases_en], q ), :must )
    query.add_query( TermQuery.new( :type, Job.to_s.downcase ), :must )
    order = orderfield( [ "aliases_#{lang}".to_sym ] )
    self.do_search query, 20, 0, order
  end

  def search_job_by_department( q, dep, lang = DEFAULT_LANG, offset = 0, limit = 20 )
    query = BooleanQuery.new
    query.add_query( self.build_livesearch_query( ["aliases_#{lang}".to_sym, :aliases_en], q ), :must )
    query.add_query( TermQuery.new( :type, Job.to_s.downcase ), :must )
    query.add_query( TermQuery.new( :department_id, dep.id.to_s ), :must )
    order = orderfield( [ "aliases_#{lang}".to_sym ] )
    self.do_search query, limit, offset, order
  end

  def search_job_by_prefix( q, lang = DEFAULT_LANG, offset = 0, limit = 20 )
    q = analyze_query(q, "aliases_#{lang}".to_sym)
    query = ""
    q.each do |term|
      query << "+(aliases_#{lang}:#{term}* aliases_en:#{term}*) "
    end
    query << "+type:job -is_department:1"
    return self.do_search(query, limit, offset)
 
#    :TODO: This is how it should be, but it isn't working the way it should..
#           compare job_ferret_test.rb
#    query = BooleanQuery.new
#    query.add_query( self.build_livesearch_query( ["aliases_#{lang}".to_sym, :aliases_en], q ), :must )
#    query.add_query( TermQuery.new( :type, Job.to_s.downcase ), :must )
#    query.add_query( TermQuery.new( :is_department, '1' ), :must_not )
#    puts query
#    order = orderfield( [ "aliases_#{lang}".to_sym ] )
#    self.do_search query, limit, offset, order
  end

  # Search for characters

  def search_characters( q, lang = DEFAULT_LANG, offset = 0, limit = 100 )
    search_localized_for_type Character, q, lang, offset, limit
  end


  # Search for Countries and Languages

  def search_languages( q, lang = DEFAULT_LANG, offset = 0, limit = 100 )
    search_localized_for_type Language, q, lang, offset, limit
  end

  def search_countries( q, lang = DEFAULT_LANG, offset = 0, limit = 100 )
    search_localized_for_type Country, q, lang, offset, limit
  end


  protected

  def search_for_query_and_type( q, type )
    query = self.filter_special_characters( q )
    "type:#{type} AND (#{query})"
  end

  def search_localized_for_type( type, q, lang, offset = 0, limit = 25 )
    query = BooleanQuery.new
    query.add_query( self.build_livesearch_query( ["aliases_#{lang}".to_sym, "name_#{lang}".to_sym, :name], q ), :must )
    query.add_query( TermQuery.new( :type, type.to_s.demodulize.downcase ), :must )
    order = orderfield [ "name_#{lang}".to_sym ]
    self.do_search( query, limit, offset, order )
  end

  def search_good_parents_for_episodes( episode, q, lang )
    movies = []
    query = BooleanQuery.new
    query.add_query( self.build_livesearch_query( [:name, "aliases_#{lang}".to_sym], q ), :must )
    query.add_query( TermQuery.new( :type, Movie.to_s.downcase ), :must )
    query.add_query( TermQuery.new( :movie_type, Series.to_s.downcase ), :must )
    ms = self.do_search( query, 25, 0 )
    ms.each { |m| 
      if m.seasons.empty?
        movies << m
      else
        movies.concat(m.seasons)
      end
    }
    movies
  end

  def build_livesearch_query( fields, q, lang = DEFAULT_LANG )
    q = filter_special_characters( q )
    query = BooleanQuery.new
    fields.uniq.each do |field|
      sq = SpanNearQuery.new(:in_order => true, :slop => 1)
      terms = analyze_query(q, field)
      terms.each do |term|
        sq << SpanPrefixQuery.new( field, term, 1024 )
      end
      query << sq
    end
    query
  end

  def orderfield( field_names, options = {} )
    options.reverse_merge! :reverse => false, :type => :string
    Sort.new( field_names.map { |field| Search::SortField.new( field, options ) } )
  end

  def build_default_query( q, lang = DEFAULT_LANG )
    sprintf( DEFAULT_QUERY, analyze_query(q, :name).join(' ') )
  end

  def build_fuzzy_query( q, lang = DEFAULT_LANG )
    return nil if q.nil? or q.empty?
    terms = analyze_query( q, "content_#{lang}".to_sym )
    terms = q.split ' ' if terms.empty? # in case we were looking for stop words only
    query = terms.collect{ |w| "#{w}~0.6" }.join(" AND ")
    "(#{query}) AND (type:movie OR type:person OR type:character)"
  end
    
  # TODO somehow do the analyzing depending on the language (stop words)
  def analyze_query(query, field_name)
    ts = Indexer.get_analyzer.token_stream(field_name, query)
    returning [] do |terms|
      while term = ts.next
        terms << term.text
      end
    end
  end

  # Remove all special ferret characters.
  def filter_special_characters( query )
    FERRET_SPECIAL_CHARS.inject(query) { |query, exp| query.gsub exp, '' }
  end

  # Remove all stop words from the query as stop words will ne be indexed
  # anyway, so it does not make sense to search for them.
  # :TODO: stop-word-filtering should be language dependent.
  # TODO: remove, now done by analyze_query
  #def filter_stop_words( q, lang = DEFAULT_LANG )
  #  query = q.split(" ")
  #  query.delete_if { |w| OmdbAnalyzer::STOP_WORDS.include?( w.downcase ) }.join(" ")
  #end

  # Execute the search and returns an array of LazyDocs.
  # A LazyDoc (see http://ferret.davebalmain.com/api/classes/Ferret/Index/LazyDoc.html) is just a basic
  # hash, that will load data upon accessing them. So if you ask for the name of an object, ferret will
  # search for a data_field ':name'. If it does not find a field of that name, it will take a look in
  # the database.
  # See custom extension to LazyDoc in app/model/lib/lazy_doc.rb
  def do_search( query, limit, offset = 0, sort = nil, filter = nil )
    results = real_search( query, 
                          :limit => limit, :offset => offset, 
                          :sort => sort, :filter => filter )
    results
  end


end
end
end
