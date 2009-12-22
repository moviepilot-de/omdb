class LogEntry < ActiveRecord::Base
  belongs_to :user
  belongs_to :language
  belongs_to :related_object, :polymorphic => true
  
  def to_s
    sprintf( "changed <strong>%s</strong> from %s to %s".t, self.attribute.t, self.old_value.to_s, self.new_value.to_s )
  end
  
  def creation?
    old_value == '0' || old_value == nil
  end

  def removal?
    (new_value.nil? || new_value == '0') && !creation?
  end

  def deletion?
    false # only assoc_log_entries
  end

  class << self
    def count_for_lang(item, lang)
      count :conditions => language_conditions( item, lang )
    end

    def find_for_lang(item, lang, conditions={})
      find :all, conditions.update(:order => 'created_at desc',
                                   :conditions => language_conditions( item, lang ) )
    end

    def language_conditions(item, lang)
      ['related_object_type=? AND related_object_id=? AND (language_id=? OR language_id=1 OR language_id is null)',
        item.toplevel_class.name, item.id, lang.id ]
    end
  end
end
