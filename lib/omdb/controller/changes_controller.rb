module OMDB
  module Controller
    module ChangesController
      
      def self.included(base) # :nodoc:
        base.extend ChangesController
      end
      
      def changes_page_for( *models )
        models.each do |model|
          define_method("changes") do
            @model       = model
            @log_entries = LogEntry.find( :all, :conditions => [ 'related_object_type = ?', model.to_s.camelize],
                                                :order => 'created_at DESC',
                                                :page => { :current => (params[:page] || 1), :size => 100 })
            render 'common/changes'
          end
        end
        
        before_filter :editor_required, :only => [ :changes ]
      end
      
    end
  end
end