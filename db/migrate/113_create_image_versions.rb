class CreateImageVersions < ActiveRecord::Migration
  def self.up
    Image.create_versioned_table
    execute "alter table `image_versions` modify `data` longblob"
    # create initial version entries to let the changelogs begin with the
    # current version
    Image.find(:all).each do |i|
      class << i
        track_changed_attributes = false
      end
      # set some reasonable default licenses en passant...
      i.license = case i.related_object
      when Episode : Image::LICENSE_FU_TVSCREEN
      when Season  : Image::LICENSE_FU_DVD
      when Movie   : Image::LICENSE_FU_POSTER
      when Person  : Image::LICENSE_FU_PERSON
      when Company : Image::LICENSE_FU_PROMO
      end
      i.save
    end
  end

  def self.down
    Image.drop_versioned_table
    remove_column :images, 'version'
  end
end
