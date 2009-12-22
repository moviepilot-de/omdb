module ImageHelper
  def image_box( url, subtitle )
    content_tag( "div", image_tag( url ) + content_tag( "div", subtitle ), 
                  :style => 'float: right;' )
  end

  def db_image_tag(image, options = {}, html_options = {} )
    fallback = options.delete(:fallback) || 'misc/no-thumbnail'
    return fallback_image(fallback, options[:action]||:default) unless image
    options.reverse_merge! image.default_url
    html_options[:src] = url_for(options.merge(:v => image.version))
    alt = options.delete(:alt) || image.description
    html_options.reverse_merge! :alt => alt
    tag 'img', html_options
  end

  def license_select_box( show_unselectable = true, object = nil )
    @item = self.instance_variable_get("@#{object.to_s}")
    current_license = @item.nil? ? -1 : @item.license 
    content_tag :select,
      content_tag( :option, "Please select a license".t, :value => Image::LICENSE_UNKNOWN ) +
      ( show_unselectable ? content_tag( :option, "I do not know the license".t, :value => Image::LICENSE_DONTKNOW ) : "" ) +
      ( show_unselectable ? content_tag( :option, "I found the image somewhere on the internet".t, :value => Image::LICENSE_FOUND ) : "") +
      content_tag( :option, "This is my own work and I want to place this image under the CC License".t, :value => Image::LICENSE_OWNWORK ) +
      content_tag( :optgroup, 
        content_tag( :option, "Creative Common License (CC)".t, :value => Image::LICENSE_FREE_CC ) +
        content_tag( :option, "GNU Free Documentation License (GFDL)".t, :value => Image::LICENSE_FREE_GFDL ) +
        content_tag( :option, "Wikimedia Commons (GFDL)".t, :value => Image::LICENSE_FREE_WC ),
        :label => "Free Licenses".t ) +
      content_tag( :optgroup,
        content_tag( :option, "License expired - Author died more than 100 years ago".t, :value => Image::LICENSE_PD_EXPIRED ) +
        content_tag( :option, "License expired - First published in the US before 1923".t, :value => Image::LICENSE_PD_PRE_1923 ) +
        content_tag( :option, "No rights reserved - Work of a government agency or similar".t, :value => Image::LICENSE_PD_NRR ),
        :label => "Public domain / no rights reserved".t ) +
      content_tag( :optgroup,
        content_tag( :option, "Fair Use image of a living person".t, :value => Image::LICENSE_FU_PERSON ),
        :label => "Fair Use".t ) +
      content_tag( :optgroup,
        content_tag( :option, "Company Logo".t, :value => Image::LICENSE_FU_LOGO ) +
        content_tag( :option, "Promotional Artwork".t, :value => Image::LICENSE_FU_PROMO ) +
        content_tag( :option, "Movie Poster".t, :value => Image::LICENSE_FU_POSTER ) +
        content_tag( :option, "DVD Cover".t, :value => Image::LICENSE_FU_DVD ) +
        content_tag( :option, "Movie Screenshot".t, :value => Image::LICENSE_FU_MOVIESCREEN ) +
        content_tag( :option, "TV Screenshot".t, :value => Image::LICENSE_FU_TVSCREEN ) +
        content_tag( :option, "Other".t, :value => Image::LICENSE_FU_OTHER ),
        :label => "Fair Use / copyrighted image".t ),
    :name => "image[license]", :id => "image_license"
  end
  
  def license_text( image )
    case image.license
      when Image::LICENSE_UNKNOWN:
        "Unknown License".t
      when Image::LICENSE_OWNWORK:
        "provided by" + " " + content_tag( :a, image.user.login, :href => url_for(:controller => "user", :id => image.user.id) )
      when Image::LICENSE_FREE_CC:
        content_tag :a, "Creative Commons", :href => url_for(:controller => "generic_page", :page => "License:CC", :action => :page )
      when Image::LICENSE_FREE_GFDL:
        content_tag :a, "GNU Free Documentation", :href => url_for(:controller => "generic_page", :page => "License:CC", :action => :page )
      when Image::LICENSE_FREE_WC:
        content_tag :a, "Wikimedia Commons", :href => url_for(:controller => "generic_page", :page => "License:WC", :action => :page )
      when Image::LICENSE_PD_EXPIRED:
        content_tag :a, "Public Domain", :href => url_for(:controller => "generic_page", :page => "License:PD:Expired", :action => :page )
      when Image::LICENSE_PD_PRE_1923:
        content_tag :a, "PD / Pre-1923 Image", :href => url_for(:controller => "generic_page", :page => "License:PD:PRE1923", :action => :page )
      when Image::LICENSE_PD_NRR:
        content_tag :a, "PD / No Rights Reserved", :href => url_for(:controller => "generic_page", :page => "License:PD:NRR", :action => :page )
      when Image::LICENSE_FU_PERSON:
        content_tag :a, "Fair Use", :href => url_for(:controller => "generic_page", :page => "License:FairUse", :action => :page )
      when Image::LICENSE_FU_LOGO:
        content_tag :a, "Fair Use", :href => url_for(:controller => "generic_page", :page => "License:FairUse", :action => :page )
      when Image::LICENSE_FU_POSTER:
        content_tag :a, "Fair Use", :href => url_for(:controller => "generic_page", :page => "License:FairUse", :action => :page )
      when Image::LICENSE_FU_PROMO:
        content_tag :a, "Fair Use", :href => url_for(:controller => "generic_page", :page => "License:FairUse", :action => :page )
      when Image::LICENSE_FU_DVD:
        content_tag :a, "Fair Use", :href => url_for(:controller => "generic_page", :page => "License:FairUse", :action => :page )
      when Image::LICENSE_FU_MOVIESCREEN:
        content_tag :a, "Fair Use", :href => url_for(:controller => "generic_page", :page => "License:FairUse", :action => :page )
      when Image::LICENSE_FU_TVSCREEN:
        content_tag :a, "Fair Use", :href => url_for(:controller => "generic_page", :page => "License:FairUse", :action => :page )
      when Image::LICENSE_FU_OTHER:
        content_tag :a, "Fair Use", :href => url_for(:controller => "generic_page", :page => "License:FairUse", :action => :page )
    end
  end
  
  def image_license_info( image )
    case image.license
      when Image::LICENSE_FU_POSTER:
        render :partial => 'fu_poster'
      when Image::LICENSE_FU_DVD:
        render :partial => 'fu_dvd'
    end
  end

  def fallback_image(image, size)
    # TODO not really DRY...
    width = case size
              when :tiny  : '45'
              when :small : '60'
              else '92' 
            end
    image_tag image, :width => width
  end

  def thumbnail_image(image, size = :tiny, fallback = 'misc/no-thumbnail')
    db_image_tag image, :action => size, :fallback => fallback
  end

  def loading_image(options = {})
    image_tag '/images/layout/loading.gif', options
  end

  def alternative_loading_image(options = {})
    image_tag '/images/layout/ajax/loading.gif', options
  end

  def delete_icon(options = {:alt => 'Delete'.t})
    image_tag '/images/icons/delete', options
  end

  def sort_icon(options = {})
    image_tag '/images/icons/sort', {:class => 'sort'}.merge(options)
  end

  def close_icon(options = {})
    image_tag '/images/icons/close', options
  end

  def alias_icon(options = {})
    image_tag '/images/icons/comment.gif', options
  end

  def plus_icon(options = {})
    image_tag '/images/icons/yes.png', options
  end
  
  def minus_icon(options = {})
    image_tag '/images/icons/no.png', options
  end

  def freeze_icon(options = {})
    image_tag '/images/icons/freeze', options
  end

  def unfreeze_icon(options = {})
    image_tag '/images/icons/unfreeze', options
  end

  def create_character_icon(options = {})
    image_tag '/images/icons/create_character', options
  end

  def break_character_icon(options = {})
    image_tag '/images/icons/break_character', options
  end

  def info_icon(options = {})
    image_tag '/images/layout/ajax/info', options.update( :height => 16, :width => 16 )
  end

  def arrow_down_icon(options = {})
    image_tag '/images/icons/arrow_down', options
  end
  
  def arrow_left_icon(options = {})
    image_tag '/images/icons/arrow_left.png', options
  end
  
  def arrow_right_icon(options = {})
    image_tag '/images/icons/arrow_right.png', options
  end
  
  def arrow_placeholder(options = {})
    image_tag '/images/icons/arrow_placeholder.png', options
  end
  
end
