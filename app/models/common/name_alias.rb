class NameAlias < ActiveRecord::Base
  include Freezable
  include Logging

  freezable_attribute :self

  belongs_to :language
  belongs_to :related_object, :polymorphic => true

  acts_as_list :scope => 'related_object_id = #{self.related_object.id} AND related_object_type = \'#{related_object.class.base_class}\''

  validates_uniqueness_of :name,
                          :scope   => [ :language_id, :related_object_id, :related_object_type ],
                          :on      => :create

  # There must no more than one official translation to a movie, for each language
  validates_uniqueness_of :official_translation,
                          :scope   => [ :language_id, :related_object_id, :related_object_type ],
                          :if      => :official_translation

  validates_presence_of :name

  disable_logging_of :official_translation, :alias_type, :version, :related_object_type, :language_id, :related_object_id, :position

  def dependent_objects
    returning ((official_translation? || related_object.class != Movie ) ? related_object.dependent_objects : {}) do |result|
      (result[related_object.base_class_name] ||= []) << related_object_id
    end
  end
  
  # Overwrite write_log in Logging
  def write_log( user = User.anonymous )
    options = { :user => user, :ip_address => user.ip_address }
    @changed_attributes.each do |a, v|
      options[:attribute] = a
      options[:old_value] = v.first
      options[:new_value] = v.last
      self.related_object.log_entries.create options unless options[:old_value].nil?
    end unless @changed_attributes.nil?
  end

end
