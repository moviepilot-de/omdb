class IncreaseImageBlob < ActiveRecord::Migration
  def self.up
    # since rails can't handle anything other than blob, we'll have to run the sql by hand
    execute "alter table `images` modify `data` longblob"
  end

  def self.down
    change_column :images, :data, :binary
  end
end
