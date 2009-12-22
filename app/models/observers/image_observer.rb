class ImageObserver < ActiveRecord::Observer

  def after_update(image)
    PageCacheSweeper.instance.expire_object image.to_hash_args
  end

end
