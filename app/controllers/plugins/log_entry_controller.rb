module LogEntryController
  def self.included(base) # :nodoc:
    base.extend ClassMethods
  end
  
  module ClassMethods

    def history_view_for( object )
      define_method("history") do
        item = instance_variable_get("@#{object.to_s}")
        lang = instance_variable_get("@language")
        count = LogEntry.count_for_lang(item, lang)
        @log_entries = LogEntry.find_for_lang(item, lang, :page => { :size => 40, :current => (params[:page] || 1) } )
        @log_entries.page = @log_entries.last_page if params[:page] and params[:page].to_i > @log_entries.last_page
        respond_to do |type|
          type.html { render 'common/history' }
          type.js { render :template => 'common/update_history_listing', :layout => false }
        end
      end
    end

  end
end
