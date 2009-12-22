module AjaxController

  def self.included(base) # :nodoc:
    base.extend AjaxController
    base.before_filter :admin_required, :only => [ :freeze_attribute, :unfreeze_attribute ]
    base.before_filter :login_required, :only => [ :new_image, :upload_image ]
    base.verify :method => :post, :only => [ :new_image, :upload_image, :set_abstract ]
    base.verify :xhr => true, :only => [ :new_image, :set_abstract ]
  end

  public 

  def info
    @size = case params[:size].to_i
              when 2: :small
              when 3: :medium
              else :tiny
            end
    @wiki_request = (params[:wiki_request] == "true")
  end

  def freeze_attribute
    object = self.instance_variable_get("@#{params[:object]}")
    object.freeze_attribute params[:attribute].to_sym
    render :nothing => true
  end

  def unfreeze_attribute
    object = self.instance_variable_get("@#{params[:object]}")
    object.unfreeze_attribute params[:attribute].to_sym
    render :nothing => true
  end

  def search_box
    render :partial => 'search_box'
  end
  
  private

  # This method allows sorting of 1:N and 1:1 relations
  def sort_action( object, attribute )
    define_method( "sort_#{object.to_s.downcase}_#{attribute}" ) do
      @object.send(attribute).each { |o|
        param  = object.to_s.downcase + "-" + attribute.to_s
        if not params[param].nil? and params[param].include?(o.id.to_s)
          o.position = params[param].index(o.id.to_s) + 1
          o.save
        end
      }
      render :nothing => true
    end
  end

  # this method allows sorting of N:N relations
  def sort_action_for_joins( object, attribute )
    tablename = "#{object.to_s}_#{attribute.to_s}"
    define_method( "sort_#{object.to_s.downcase}_#{attribute}" ) do
      counter = 1
      param  = object.to_s.downcase + "-" + attribute.to_s
      if not params[param].nil?
        params[param].each { |element|
          id    = element.split('_').last.to_i
          klass = Module.const_get(Inflector.singularize( attribute.to_s ).camelize)
          so    = klass.find(id)
          if @object.send(attribute).include?(so)
            ActiveRecord::Base.connection.update( "update #{tablename} set position = #{counter} where #{object.to_s}_id = #{@object.id} and #{klass.to_s.downcase}_id = #{so.id}" )
            counter = counter.next
          end
        }
      end
      render :nothing => true
    end
  end

  def create_has_many_relation( object, attribute )
    define_method( "create_#{attribute.to_s}" ) do
      if params[attribute].nil?
        raise "Illegal State in create_has_many_relation"
      else
        @relation = attribute.to_s.camelize.constantize.find(params[attribute])
        method   = "add_" + attribute.to_s.pluralize
        @item    = object.to_s.camelize.constantize.find(params[:id])
        @item.send(method, @relation) unless @item.send(method).include?( @relation )
      end
    end
  end

  def lightbox_edit_for( object, attribute, success_template )
    define_method( "set_#{attribute.to_s.downcase}" ) do
      if not params[object.to_s].nil? and not params[object.to_s][attribute.to_s].nil?
        item = self.instance_variable_get("@#{object.to_s}")
        if item.send(attribute.to_s + "=", params[object.to_s][attribute.to_s]) and item.save
          render :partial => success_template.to_s, :locals => { :close_box => true }
        else
          flash[:errors] ||= []
          if not item.errors.on(attribute).nil?
            flash[:errors] << [attribute, item.errors.on(attribute).first]
          end
          render(:update) { |page| 
            page.show('error-messages')
            page.replace_html('error-messages', show_errors)
          }
        end
      end
    end
  end
  
  def help_view( name )
    name.each do |n|
      method_name = "help_#{n}"
      define_method( method_name ) do
        render "help/#{self.controller_name}_#{method_name}"
      end
    end
  end

  def set_abstract_for( object )
    class_eval do
      verify :method => :post, :only => [ :set_abstract ]
      verify :xhr => true, :only => [ :set_abstract ]
    end
    
    define_method( "set_abstract" ) do
      item = self.instance_variable_get("@#{object.to_s}")
      @abstract = item.abstract( @language )

      if not params[object].nil? and not params[object][:abstract].nil?
        if @abstract.new_record?
          @abstract.related_object = item
          @abstract.language = @language
        end
        @abstract.data = params[object][:abstract]
        if @abstract.save
          render(:update) { |page|
            page.replace 'overview-abstract', :partial => 'content/overview_abstract', :locals => { :abstract => @abstract }
            page.call('box.deactivate')
          }
        else 
          render(:update) { |page| 
            page.replace_html 'abstract_errors', error_message_on( :abstract, :data )
            page << "$('abstract_submit').disabled = false;"
          }
        end
      else
        render 'common/set_abstract'
      end
    end
  end
  
  
  # Create edit_alias methods for the current controller. This method will create
  # the methods :edit_aliases, :create_alias, :destroy_alias, :show_all_aliases, 
  # :show_less_aliases and :sort_name_aliases
  def edit_aliases_for( object, options = { :language_independent => false, :allow_independent => false } )
    # before_filter :login_required, :only => [ :destroy_alias ]
    
    cache_sweeper :name_alias_log_observer
    
    # verify :method => :get, :only => [ :edit_aliases ]
    # verify :method => :post, :only => [ :destroy_alias, :sort_name_aliases ]
    verify :xhr => true, :only => [ :create_alias, :destroy_alias, :show_less_aliases, :show_less_aliases, :sort_name_aliases ]

    define_method( :edit_aliases ) do
      @item = self.instance_variable_get("@#{object.to_s}")
      @language_independent = true if options[:language_independent]
      @allow_independent = true if options[:allow_independent] and not options[:language_independent]
      @aliases = @item.aliases if options[:language_independent]
      render 'common/edit_aliases'
    end
    
    # Create the method :create_alias, needed to create new aliases
    define_method( :create_alias ) do
      @item = self.instance_variable_get("@#{object.to_s}")
      if not params[:alias][:name].empty?
        a = NameAlias.new(:name => params[:alias][:name])
        a.language = Language.find(params[:alias][:language])
        @item.aliases << a
        if not a.save
          @aliases = @item.aliases
          flash[:errors] = a.errors
          # :TODO: fix that
          # render :update do |page|
          #  page.replace_html 'edit_new', :partial => 'common/new_alias'
          # end
        end
      end
      render(:update) do |page|
        if options[:language_independent]
          page.replace 'overview-aliases', :partial => 'common/overview_aliases_lang_independent', :locals => { :object => @item }
        else
          page.replace 'overview-aliases', :partial => 'common/overview_aliases', :locals => { :object => @item, :local_aliases_only => true }
        end
        page.replace_html 'headline', :partial => 'headline'
        page << "box.deactivate()"
      end
    end
    
    # destroy a single name_alias
    define_method( :destroy_alias ) do
      @item = self.instance_variable_get("@#{object.to_s}")
      a = NameAlias.find params[:alias] 
      if a.related_object == @item and not a.frozen?
        a.destroy
        render :update do |page|
          page.replace_html 'headline', :partial => 'headline'
          page.visual_effect :fade, "edit-alias-" + a.id.to_s
          page.remove "name_alias_" + a.id.to_s
        end
      end
    end
    
    # Show all aliases of an item, ordered by languages
    define_method( :show_all_aliases ) do
      @all_languages = true
      @item = self.instance_variable_get("@#{object.to_s}")
      render(:update) do |page|
        page.visual_effect :blind_up, 'overview-aliases'
        page.delay(1.2) do
          page.replace 'overview-aliases', :partial => 'common/overview_aliases', :locals => { :object => @item, :local_aliases_only => false }
          page.visual_effect :blind_down, 'overview-aliases'
        end
      end
    end

    # Show only the aliases of the current language of the user
    define_method( :show_less_aliases ) do
      @item = self.instance_variable_get("@#{object.to_s}")
      render(:update) do |page|
        page.visual_effect :blind_up, 'overview-aliases'
        page.delay(1.2) do
          page.replace 'overview-aliases', :partial => 'common/overview_aliases', :locals => { :object => @item, :local_aliases_only => true }
          page.visual_effect :blind_down, 'overview-aliases'
        end
      end
    end
  
    define_method( :sort_name_aliases ) do
      param  = "name_aliases_" + @language.id
      if not params[param].nil?
        params[param].each do |p|
          name_alias = NameAlias.find(p.split(/_/).last)
          name_alias.position = params[param].index(p) + 1
          name_alias.save
        end
      end
      render :nothing => true
    end
  
  end

  def image_upload_for( object, options = {} )
    define_method( :new_image ) do
      @foto_foo = options[:foto_foo] || false
      render 'common/new_image'
    end
    
    define_method( :upload_image ) do
      @item = self.instance_variable_get("@#{object.to_s}")
      if @item.image.nil?
        @image = Image.new
        @image.related_object = @item
      elsif @item.image.attribute_frozen?(:self)
        render :nothing => true, :status => 401
      else
        @image = @item.image
      end
      @image.uploaded_data = params[:file][:data]
      @image.attributes = params[:image]
      @image.user = current_user
      if not @image.save
        flash[:error] = "Error!"
      end
      redirect_to :action => :index, :dontcache => @image
    end
  end

  def refresh_action( klass, id )
    define_method( "refresh_#{id.to_s.downcase}" ) do
      render :update do |page| 
        page.replace_html id.to_s.gsub(/_/, '-'), :partial => klass.to_s + '/' + id.to_s.downcase 
      end 
    end
  end

  def update_relation_action_for( object, name )
    define_method( "update_#{name}" ) do
      item = self.instance_variable_get("@#{object.to_s}")
      return if item.attribute_frozen?( name )
      if not item.attribute_frozen?( name )
        item.send(name.to_s + "=", [])
        relations = []
        params[name].each { |id|
          relations << name.to_s.singularize.camelize.constantize.find( id )
        } unless params[name].nil?
        item.send( name.to_s + "=", relations )
      end
    end
  end

  def set_parent_for( object, parent_id )
    parent = object.class.find( parent_id )
    if not (object == parent) and not object.all_children.include?(parent)
      object.parent = parent
      object.save!
    end
  end
  
  def movie_list_for( object, options = { :method => 'all_movies_paged', :action_name => 'movies' } )
    puts "defining #{options[:action_name]}"
    define_method( options[:action_name] ) do
      item = self.instance_variable_get("@#{object.to_s}")
      @results = item.send(options[:method], (params[:page] || 1 ))
      respond_to do |type|
        type.html { render 'common/movies' }
        type.js { render :template => 'common/update_search_listing', :layout => false }
      end
    end    
  end

end
