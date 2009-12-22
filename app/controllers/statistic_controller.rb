require 'gruff'

class StatisticController < ApplicationController

  before_filter :select_object, :except => [ :movies ]

  if not defined?(DEFAULT_THEME)
    DEFAULT_THEME = { :colors => %w(#4e4e4d red),
                      :marker_color => 'black',
		      :background_image => "#{RAILS_ROOT}/public/images/default-background.jpg" }
  end
  
  TOP_MARGIN = 0.0
  BOTTOM_MARGIN = 0.0
  RIGHT_MARGIN = 0.0
  LEFT_MARGIN = 0.0  	   	
  

  private

  def select_object
    ["movie", "person", "country", "company", "category"].each { |type|
      if not params[type].nil?
        @object = type.camelcase.constantize.find params[type]
      end
    }
  end

  public
 
  def movies_per_year
    data, labels = @object.movies_per_year
    build_image data, labels, "Movies per year".t
  end

  def quality_per_year
    data, labels = @object.quality_per_year
    build_image data, labels, "Quality per year".t, 10.0
  end
  
  def movies
    data = []
    labels = {}
    (1..52).each do |i|
      data << Movie.find( :all, :conditions => [ "created_at < ?", (52 - i).weeks.ago ] ).size
      labels[i] = (52 - i).to_s if i % 2 == 0
    end
    max = ((Movie.count / 1000) + 1) * 1000
    build_image data, labels, "number of movies in the db (last 52 weeks)".t, max, 600, true
  end
  
  def movie_by_rating
    data = @object.movie_by_rating
    build_pie_chart data, 'bla', 'blub'
  end
  
  def movie_rating_by_gender(gender=params[:gender])
    data = @object.movie_rating_by_gender(gender)
    build_pie_chart data, 'bla', 'blub', nil, '108x110'
  end

  def movie_voting_per_week
    data, labels = @object.movie_votes_per_week(25,51,2006)
    build_land_chart data, labels, "Voting per Week".t, 10.0
  end 
  
  def movie_popularity_per_week
    data, labels = @object.movie_popularity_per_week(25,51,2006)
    build_land_chart data, labels, "Popularity per Week".t, Movie.count().to_i
  end
  
  def movie_rating_by_country(country=params[:country])
    data = @object.movie_rating_by_country(country)
    build_pie_chart data, 'bla', 'blub'
  end
  
  def movie_rating_by_continent(continent=params[:continent])
    data = @object.movie_rating_by_continent(continent)
    build_pie_chart data, 'bla', 'blub', nil, '108x110'
  end

  private 

  def build_image( data, labels, title, maximum_value = nil, size = 485, hide_dots = false )
    g = Gruff::Line.new( size )
    g.maximum_value = maximum_value unless maximum_value.nil?
    g.minimum_value = 0 unless maximum_value.nil?
    g.theme = DEFAULT_THEME
    g.hide_title = true
    g.hide_dots  = hide_dots

    g.data(title, data)
    g.labels = labels

    send_data(g.to_blob,
              :disposition => 'inline', 
              :type => 'image/png', 
              :filename => "bart_scores.png")
  end
  
  def build_pie_chart ( data, labels, title, maximum_value = nil, size = '218x180')
    g = Gruff::Pie.new(size)
    g.hide_legend = true
    g.marker_font_size = 45
    g.theme = { :colors => %w(#fdf2e6 #fce5cf #fbd9bb #FFC18F #FFB479 #FFA764 #FF9A51 #FF8E3D #FF8329 #FE770E),
                :marker_color => 'white', 
                :background_colors => %w(#dde4d6 #dde4d6) }
    10.times do |i| 
      g.data i, data[i] if data[i] 
    end
        
    send_data(g.to_blob,
              :disposition => 'inline',
              :type => 'image/png',
              :filename => "some_bla.png")
  end

  def build_land_chart ( data, labels, title, maximum_value = nil)
    g = Gruff::Area.new('218x180')
    g.hide_legend = true
    #g.marker_font_size = 45
    g.maximum_value = 10.0
    g.minimum_value = 0 unless maximum_value.nil?
    g.theme = { :colors => %w(#FF8E3D #fdf2e6 #fce5cf #fbd9bb #FFC18F #FFB479 #FFA764 #FF9A51 #FF8E3D #FF8329 #FE770E),
                :marker_color => 'white', 
                :background_colors => %w(#dde4d6 #dde4d6) }

    g.labels = labels

    g.data(title, data)


        
    send_data(g.to_blob,
              :disposition => 'inline',
              :type => 'image/png',
              :filename => "some_bla.png")
  end


end
