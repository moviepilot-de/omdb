class ImageController < ApplicationController
  include AjaxController
  include Magick

  verify :method => :post, :only => :upload

  before_filter :select_image,  :except => [ :upload, :new_image ]
  before_filter :editor_required, :only => :history
  
  GEOMETRIES = {
    :tiny    => '45',
    :small   => '60',
    :medium  => { :width => 92, :max_height => 142 },
    :embed   => { :width => 140, :max_height => 300 },
    :wiki    => '250',
    :default => '198'
  } unless defined? GEOMETRIES

  caches_page :index, :view, *GEOMETRIES.keys

  include PageActions

  GEOMETRIES.each_pair do |name, geometry|
    if Hash === geometry
      geometry_string = "#{geometry[:width]}x"
    else
      geometry_string = geometry
    end
    define_method name do
      @magick_image.change_geometry(geometry_string) do |c, r, img|
        img.resize! c, r
        img.crop! Magick::NorthWestGravity, geometry[:width], geometry[:max_height] if Hash === geometry
      end
      display
    end
  end

  public

  # overridden to disable most of the usual wiki functionality
  # TODO: fix edit_page and update_page to copyright pages, too.
  def page
    redirect_to :action => 'copyright'
  end

  def copyright
    @page = @image.wiki_index Locale.base_language 
  end

  def index
    default
  end

  def view
    display
  end

  def edit_facts
    render :action => 'edit_facts', :layout => 'ajax_box'
    
  end

  def display
    if not @image.nil?
      send_data( @magick_image.to_blob,
                :filename => @image.filename,
                :type     => @magick_image.mime_type,
                :disposition => 'inline' )
    end
  end
  
  def upload
    image = ::Image.create!(:uploaded_data => params[:picture])
    image.name_aliases.create(:name => params[:description], :language => @language)
    render :text => %{<script type="text/javascript" charset="utf-8">window.close()</script>}
  end

  def history
    @versions = @image.versions
  end
    
  private 

  def determine_layout
    "default" unless %w(new_image upload).include?(params[:action])
  end
  
  def select_image
    if params[:fname] =~ IMAGE_FILENAME # regex declared in routes.rb
      @image = ::Image.find($1) rescue nil
      @image = @image.find_version($3) if @image && $3
    else
      @image = ::Image.find(params[:id]) rescue nil
    end

    if @image && !@image.data.blank?
      @image = @image.find_version params[:rev] if params[:rev]
      @magick_image = @image.to_magick
    end

    handle_404 unless @magick_image
  end

  def fetch_no_cover
    @image = ::Image.new()
    @magick_image = Image.read(File.join("#{RAILS_ROOT}", "public", "images", "no_cover185px.png")).first
  end
  
  def title( lang = Locale.base_language )
    ""
  end

  def register_tabs
    @tabs = [
      { :name => "Copyright Information".t, :url  => { :action => 'copyright' } }
    ]
    @tabs << { :name => "Versions".t, :url  => { :action => 'history' } } if editor?
  end
  def related_object; @image end
  
end
