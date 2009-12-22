# controller serving 'generic' content pages
class GenericPageController < ApplicationController
  include PageActions

  before_filter :editor_required, :except => [ :page, :rss, :changelog ]
  before_filter :set_page_style, :only => :page

  protected

  def find_page
    page_name = requested_page_name
    @page = Page.generic_page_for_language page_name, @language
    @page ||= Page.find(:first,
                        :conditions => [ 'page_name=? AND related_object_id is NULL',
                                          page_name ]
                       )
    @page ||= Page.new(:language_id => @language.id, :page_name => page_name, :name => page_name)

    @related_object = @page
    @page = @page.get_version(params[:rev]) if params[:rev]
  end

  def requested_page_name
    Hash === params[:page] ? params[:page][:name] : params[:page]
  end

  def related_object; @related_object end

  def register_tabs
    @tabs = [
      { :name => "Page".t,     :url => { :action => 'page' } },
      { :name => "Versions".t, :url => { :action => 'changelog' } }
    ]
  end

  def set_page_style; @page_style = 'broadpage' end

end
