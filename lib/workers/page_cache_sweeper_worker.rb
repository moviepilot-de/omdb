class PageCacheSweeperWorker < BackgrounDRb::Rails
  include FileUtils

  first_run Time.now.to_s(:db)
  repeat_every 15.minutes

  @@pages = {}
  def self.expire_page(page, options = {})
    @@pages[page] = options
  end

  # configuration of pages to expire, path is relative to
  # RAILS_ROOT/public/(anonymous|logged_in)/(en|de)/
  expire_page 'movie.html', :after => 6.hours

  # (possibly a) TODO: with minor changes in page_cache_sweeper 
  # this one could expire all files in the movie controller cache 
  # older than 6 hours:
  # expire_page 'movie', :after => 6.hours

  def do_work(args)
    @logger.debug "scheduled page cache expiration running"
    sweeper = PageCacheSweeper.instance
    @@pages.each_pair do |page, options|
      sweeper.delete page do |full_path|
        exp = expired?( full_path, options )
        @logger.debug "expiring #{full_path}" if exp
        exp
      end
    end
  end

  protected

  def expired?(path, options)
    max_age = options[:after]
    File.mtime(path) < max_age.ago if File.exists?(path)
  end

end
