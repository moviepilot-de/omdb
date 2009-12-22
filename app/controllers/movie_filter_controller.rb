class MovieFilterController < ApplicationController

  layout nil

  def show_filter_dialog
    self.instance_variable_set( "@#{params[:from]}", params[:from].camelize.constantize.find( params[:id] ) )
    render :update do |page|
      page.replace_html 'movie_filter', :partial => 'show_filter_dialog'
      page.hide 'filter_control'
      page.show 'hide_filter_control'
    end
  end
  
  def hide_filter_dialog
    render :update do |page|
      page.hide 'movie_filter'
      page.hide 'hide_filter_control'
      page.show 'filter_control'
      page.replace_html 'movie_filter', '<div class="loading">&nbsp;</div>'
    end
  end

  def update_filter
    @filter = MovieFilter.new
    [ "person_ar", "country_ar", "category_ar", "keyword_ar" ].each { |key|
      if not params[key].nil?
        if key == "keyword_ar"
          field = "category"
        else
          field = key.split("_").first
        end
        params[key].each { |id|
          @filter.send("add_#{field}_id", id )
        }
      end
    }
    @offset = (params[:offset].nil? ? 0 : params[:offset].to_i)
    @movies = Searcher.search_filtered_movies("*", @filter, @language.code)
    render :update do |page|
      rest = @movies.size - @offset - 24
      movie_ids = @movies.slice(@offset, 24).collect{|m| m.id.to_s}
      page.call "movies = new MovieFilter", "movies"
      page.call "movies.showMovies", movie_ids, @offset, rest
    end
  end

end
