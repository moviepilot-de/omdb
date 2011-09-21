class ReferenceController < ApplicationController
  include AjaxController

  before_filter :select_reference, :except => [ :random ]
  before_filter :login_required, :only => [ :destroy ]

  def random
    @reference = Reference.random
    respond_to do |type|
      type.html { render :action => :index }
      type.js { render :inline => "#{@reference.referenced_movie.id};#{@reference.class.to_s};#{@reference.movie.id}" }
    end
  end

  def destroy
    id = @reference.id
    @movie = @reference.movie
    @reference.destroy
    render(:update) do |page|
      page.remove "movie-reference-#{id}"
      page.replace_html 'overview-references', :partial => 'movie/overview_references'
    end
  end

  private

  def select_reference
    @reference = Reference.find(params[:id])
  end

  def title
    "Random Reference".t
  end

end
