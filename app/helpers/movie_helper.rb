module MovieHelper

  def link_text_for_movie( movie )
    if movie.class == Season and not movie.parent.nil?
      text = title_for_movie(movie.parent) + " &gt; " + title_for_movie(movie)
    elsif movie.class == Episode and not movie.parent.nil? and not movie.parent.parent.nil?
      text = title_for_movie(movie.parent.parent) + " &gt; " + title_for_movie(movie)
    else
      text = title_for_movie(movie)
    end
    text = text + " (#{movie.end.year})" unless movie.end.nil?
    text
  end
  
  def local_title
    local_title_for_movie @movie
  end

  def title_for_movie( movie )
    if movie.class == Episode and not movie.parent.nil? and not movie.parent.parent.nil?
      (local_title_for_movie(movie.parent.parent).nil? ? movie.parent.parent.name : local_title_for_movie(movie.parent.parent)) + " > " + (local_title_for_movie(movie).nil? ? movie.name : local_title_for_movie(movie))
    else
      local_title_for_movie(movie).nil? ? movie.name : local_title_for_movie(movie)
    end
  end

  def local_title_for_movie( movie )
    movie.official_translation(@language).any? ? movie.official_translation(@language).first.name : nil
  end

  def valid_countries
    countries = Country.find :all, :order => 'name'
    countries.delete_if { |c| @movie.countries.include?(c) }
  end

  def runtime_for_season( season )
    runtime = 0
    season.children.each { |child|
      runtime = runtime + child.runtime
    }
    runtime
  end

  def category_type_hash
    categories = {}
    @movie.categories.each { |c|
      categories[c.root] = [] if categories[c.root].nil?
      categories[c.root].push(c)
    }
    categories
  end

  def movie_class_options_for_select
    options = ''
    Movie.valid_types.each { |type|
      type = type.to_s
      options << "<option value=\"#{type}\">#{type.t}</option>"
    }
    options
  end

  def production( movie = @movie )
    if movie.production_year.is_a? Range
      link_to( movie.production_year.first.to_s, { :controller => 'year', :id => movie.production_year.first } ) + " - " +
      link_to( movie.production_year.end.to_s, { :controller => 'year', :id => movie.production_year.end } )
    elsif movie.production_year.nil?
      "n/a"
    else 
      link_to( movie.production_year.to_s, { :controller => 'year', :id => movie.production_year } )
    end
  end

  def movie_vote( movie = @movie )
    sprintf("%1.2f", movie.vote)
  end

  def directors_for_series
    directors = {}
    html = ''
    @movie.children.each { |m|
      m.directors.each { |d|
        directors[d.person] = [] if directors[d.person].nil?
        directors[d.person].push(m)
      }
    }
    d = directors.sort { |a, b| a[0].name <=> b[0].name }
    d.slice(0,5).each { |person, movies|
      html += '<tr><td>' + link_to_object(person) + '</td><td><ul>'
      movies.slice(0,5).each {|m| 
        html += '<li>'
        html += link_to_object(m)
        html += '</li>' 
      }
      html += '</ul></td></tr>'
    }
    html
  end

  def sort_cast_link( department )
    id = "link-sort-movie-" + department.id.to_s
    link_to_remote "sort".t,
                  { :url => { :controller => 'movie', 
                              :action => "activate_cast_sorting", 
                              :type => "movie-" + department.id.to_s } },
                  { :id    => id,
                    :title => "Sort this list".t,
                    :class => "edit-button" }
  end
  
  def category_vote_icons_link
    content_tag( :p,
      "do you agree to these categories? you can help redefine these categories by %s" /
        link_to_remote( 'voting'.t, { :url => { :action => :display_category_vote_icons } }, 
                                      :id => 'display_category_vote_icons', 
                                      :class => 'edit' ),
      :class => "vote-text" )
  end
  
  def keyword_vote_icons_link
    content_tag( :p,
      "do you agree to these keywords? you can help redefine the relevant keywords by %s" /
        link_to_remote( 'voting'.t, { :url    => { :action => :display_keyword_vote_icons } },
                                      :id     => 'display_keyword_vote_icons', 
                                      :class  => 'edit' ),
      :class => "vote-text" )
  end

  def movies_by_type( movie )
    movies = {}
    movie.children.each{ |m|
      movies[m.class] = [] if movies[m.class].nil?
      movies[m.class].push(m)
    }
    movies
  end
  
  # :TODO: calculate the real weight of plot keywords
  def tag_cloud( keywords )
    sorted_keywords = keywords.sort { |a,b| a.local_name( @language ) <=> b.local_name( @language ) }
    sorted_keywords.collect do |c|
      i = (keywords.index(c) < 4) ? 1 : ((keywords.index(c) < 6) ? 2 : ((keywords.index(c) < 10) ? 3 : 4))
      link_to( c.local_name( @language ).gsub(" ", "&nbsp;"), { :controller => c.base_class_name.to_s.downcase, :id => c.id, :action => :index }, :class => "weight_#{i}" )
    end.join(", ")
  end
  
  # allows a value for the vote eg. 1 for positive -1 for negative, default is positive
  def has_voted(user_id, movie, category, value = 1)
    vote = MovieUserCategory.find(:first,
                                  :conditions => [ "user_id = ? and movie_id = ? and category_id = ? and value = ?",
                                                   user_id, movie.id, category.id, value ])
    if vote.nil?
      false
    else
      true
    end
  end
  
  def reference_text
    case params[:reference_class]
      when Homage.to_s.underscore
         "%s is a homage to" / title_for_movie(@movie)
      when Influence.to_s.underscore
        "%s was influenced by" / title_for_movie(@movie)
      when Parody.to_s.underscore
        "%s is a parody of" / title_for_movie(@movie)
      when Remake.to_s.underscore:
        "%s is a remake of" / title_for_movie(@movie)
      when SpinOff.to_s.underscore:
        "%s is a spin off of" / title_for_movie(@movie)
      else
        "%s is a #{params[:reference_class].humanize} to" / title_for_movie(@movie)
    end
  end
  
  def references_by_type( refs )
    references = {}
    Reference.valid_types.each do |type|
      references[type] = []
    end
    refs.each do |ref|
      references[ref.class] << ref
    end
    references
  end
  
  def review_vote_color(vote, reverse=false)
    colors = Hash.new
    if reverse
      colors = {9 => '#fdf2e6', 8 => '#fce5cf', 7 => '#fbd9bb', 6 => '#FFC18F', 5 => '#FFB479', 4 => '#FFA764', 3 => '#FF9A51', 2 => '#FF8E3D', 1 => '#FF8329', 0 => '#FE770E'}
    else
      colors = {0 => '#fdf2e6', 1 => '#fce5cf', 2 => '#fbd9bb', 3 => '#FFC18F', 4 => '#FFB479', 5 => '#FFA764', 6 => '#FF9A51', 7 => '#FF8E3D', 8 => '#FF8329', 9 => '#FE770E'}
    end
    return colors[vote]
  end
  
  def create_new_choice_button
    case @movie.class.to_s
      when "MovieSeries"
        return hidden_field_tag( 'parent_movie', @movie.id ) +
          hidden_field_tag( 'movie[class]', 'Movie' ) +
          submit_tag( "Create a new movie as part of \"%s\"" / link_text_for_movie(@movie) )
      when "Series"
        return hidden_field_tag( 'parent_movie', @movie.id ) +
          hidden_field_tag( 'movie[class]', 'Season' ) +
          submit_tag( "Create a new season for \"%s\"" / link_text_for_movie(@movie) )
      when "Season"
        return hidden_field_tag( 'parent_movie', @movie.id ) +
          hidden_field_tag( 'movie[class]', 'Episode' ) +
          submit_tag( "Create a new episode for \"%s\"" / link_text_for_movie(@movie).gsub(/&gt;/, '>') )
      when "Episode"
        return hidden_field_tag( 'parent_movie', @movie.parent.id ) +
          hidden_field_tag( 'movie[class]', 'Episode' ) +
          submit_tag( "Create a new episode for \"%s\"" / link_text_for_movie(@movie.parent).gsub(/&gt;/, '>') ) unless @movie.parent.nil?
      when "Movie"
        return hidden_field_tag( 'parent_movie', @movie.parent.id ) +
          hidden_field_tag( 'movie[class]', 'Movie' ) +
          submit_tag( "Create a new movie as part of \"%s\"" / link_text_for_movie(@movie.parent).gsub(/&gt;/, '>') ) unless @movie.parent.nil?
    end
  end
  
  def local_alias_select_options( movie, lang )
    local_title = local_title_for_movie( movie )
    content_tag( :option, "Same as original title".t, :value => 0 ) +
    content_tag( :option, "Enter new title in %s"/( @language.english_name.t.downcase ), :value => 'new' ) +
    ( movie.local_aliases( lang ).empty? ? "" : content_tag( :optgroup, 
      movie.local_aliases( lang ).collect do |a|
        if a.name == local_title
          content_tag( :option, a.name, :selected => true, :value => a.id )
        else
          content_tag( :option, a.name, :value => a.id )
        end
      end.join(""),
      :label => "Use existing #{@language.english_name} title".t
    ) )
  end

  def average_votes( movie_list )
    vote = 0
    movie_list.each { |m|
      vote = vote + m.vote
    }
    sprintf "%1.2f", ( movie_list.empty? ? 0 : vote / movie_list.size )
  end

end

