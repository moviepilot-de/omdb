class LanguageController < ApplicationController
  self.extend(AjaxController)

  before_filter :select_movie, :select_language

  def determine_layout
    if request.xhr?
      "ajax_box"
    else
      "default"
    end
  end


  def select_movie
    @movie = Movie.find(params[:movie])
  end

  def select_language
    @language = Language.find(params[:id])
  end

  def language_info
  end
end
