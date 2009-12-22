# OmdbAnalyzer
# 
# Custom Analyzer to map all non-ascii characters to ascii characters.
# This will help omdb users to search for names if they are not sure 
# about the correct spelling of the name.
# 
# So it doesn't matter if it's "François Truffaut" or "Francois Truffaut"
# or "Francôis Truffaut".
#
# Author:: Benjamin Krause <bk@benjaminkrause.com>, Jens Kraemer <jk@jkraemer.net>

module OMDB
  module Ferret
    CHARACTER_MAPPINGS = {
      ['à','á','â','ã','ä','å','ā','ă']         => 'a',
      'æ'                                       => 'ae',
      ['ď','đ']                                 => 'd',
      ['ç','ć','č','ĉ','ċ']                     => 'c',
      ['è','é','ê','ë','ē','ę','ě','ĕ','ė',]    => 'e',
      ['ƒ']                                     => 'f',
      ['ĝ','ğ','ġ','ģ']                         => 'g',
      ['ĥ','ħ']                                 => 'h',
      ['ì','ì','í','î','ï','ī','ĩ','ĭ']         => 'i',
      ['į','ı','ĳ','ĵ']                         => 'j',
      ['ķ','ĸ']                                 => 'k',
      ['ł','ľ','ĺ','ļ','ŀ']                     => 'l',
      ['ñ','ń','ň','ņ','ŉ','ŋ']                 => 'n',
      ['ò','ó','ô','õ','ö','ø','ō','ő','ŏ','ŏ'] => 'o',
      'œ'                                       => 'oek',
      'ą'                                       => 'q',
      ['ŕ','ř','ŗ']                             => 'r',
      ['ś','š','ş','ŝ','ș']                     => 's',
      ['ť','ţ','ŧ','ț']                         => 't',
      ['ù','ú','û','ü','ū','ů','ű','ŭ','ũ','ų'] => 'u',
      'ŵ'                                       => 'w',
      ['ý','ÿ','ŷ']                             => 'y',
      ['ž','ż','ź']                             => 'z'
    }
    
    class OmdbAnalyzer < ::Ferret::Analysis::Analyzer 
      include ::Ferret::Analysis 
    end
    
    class OmdbDefaultAnalyzer < OmdbAnalyzer
      def token_stream(field, str)
        MappingFilter.new( HyphenFilter.new( 
          LowerCaseFilter.new( StandardTokenizer.new(str) ) ), CHARACTER_MAPPINGS )
      end
    end
    
    class OmdbContentAnalyzer < OmdbAnalyzer
      def initialize( language = Locale.base_language )
        @stop_words = "::Ferret::Analysis::FULL_#{language.english_name.upcase}_STOP_WORDS".constantize
        @language = language
      end
      
      def token_stream(field, str)
        MappingFilter.new( StemFilter.new( StopFilter.new( 
          LowerCaseFilter.new( StandardTokenizer.new(str) ), 
          @stop_words ), @language.code ), CHARACTER_MAPPINGS )
      end
    end
  end
end

module Ferret::Analysis
  class PerFieldAnalyzer < ::Ferret::Analysis::Analyzer
    def initialize( default_analyzer )
      @analyzers = {}
      @default_analyzer = default_analyzer
    end
        
    def add_field( field, analyzer )
      @analyzers[field] = analyzer
    end
    alias :[]= :add_field
        
    def token_stream(field, string)
      @analyzers.has_key?(field) ? @analyzers[field].token_stream(field, string) : 
        @default_analyzer.token_stream(field, string)
    end
  end
end
