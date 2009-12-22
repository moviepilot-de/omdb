module PageHelper
  include Wiki::WikiHelper

  def link_to_page(page = @page, value = nil)
    value ||= page.page_name
    link_to value, url_for_page('page', page)
  end

  def rename_link(page = @page)
    link_to_function "rename page".t, 
                     lightbox(url_for_page('rename_page', page)),
                     :class => 'edit-button'
  end

  def edit_link(page = @page, text = nil, style = 'edit-button')
    text = text.nil? ? "#{page.new_record? ? 'create':'edit'} article".t : text
    link_to text.t, url_for_page('edit_page', page), :class => style
  end
  
  def destroy_link(page = @page, style = 'edit-button')
    link_to 'delete page'.t, url_for_page('destroy_page', page), :class => style, :confirm => 'Artikel wirklich löschen?'.t, :post => true
  end
  
  def create_page_link
    link_to_function 'create article'.t,
                     lightbox(url_for_page('new_page', nil)),
                     :class => 'edit-button'
  end

  def other_languages
    if related_object
      @other_languages ||= related_object.index_page_languages - [@language]
    else
      []
    end
  end


  def url_for_page(action, page = @page)
    returning url_options = { :action => action } do
      if action == 'page' && page.page_name == 'index'
        url_options[:action] = 'index'
      else
        url_options[:page] = page.page_name if page
      end
      url_options[:id] = related_object.id unless Page === related_object
    end
  end

end
