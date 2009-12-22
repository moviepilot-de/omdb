class Admin::TranslateController < ApplicationController
  
  before_filter :admin_required
  
  def index
    @translation_pages, @translations =
      paginate :translations, :conditions => ['language_id = ?', @language.id], :order => :tr_key, :per_page => 40
  end

  def translation_text
    @translation = ViewTranslation.find(params[:id])
    render :text => @translation.text || ""  
  end

  def set_translation_text
    @translation = ViewTranslation.find(params[:id])
    previous = @translation.text
    @translation.text = params[:value]
    @translation.text = previous unless @translation.save
    render :partial => "translation_text", :object => @translation.text  
  end
  
  def destroy
    @translation = ViewTranslation.find(params[:id])
    @translation.destroy
    render(:update) do |page|
      page.visual_effect :fade, 'tr_row_' + params[:id].to_s
    end
  end
end
