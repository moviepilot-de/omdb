require 'fileutils'

class PageCacheSweeper
  include Singleton, FileUtils

  LOGGER = Logger.new("#{RAILS_ROOT}/log/page_cache_sweeper.log") if defined? RAILS_ROOT
  
  # :type - class name
  # :id   - id
  def expire_object(args)
    clazz = args[:type].constantize
    case args[:type]
    when 'Image'     : expire_image args[:id]
    when 'NameAlias' : return
    else
      LOGGER.info "expire object #{clazz} #{args[:id]}"
      controller = clazz.base_class.name.demodulize.underscore
      path = "#{controller}/#{args[:id]}"
      if controller =~ ENCYCLOPEDIA_CONTROLLERS
        path = "encyclopedia/#{path}"
      end
      delete path
    end
  end

  def delete(path, locales = LOCALES)
    locales.each_key do |locale|
      %w( logged_in anonymous ).each do |login_status|
        [ '.html', '' ].each do |suffix|
          full_path = "#{RAILS_ROOT}/public/#{login_status}/#{locale}/#{path}#{suffix}"
          expire full_path if !block_given? || yield(full_path)
        end
      end
    end
  end

  def expire_image(id)
    LOGGER.info "expire image #{id}"
    actions = %w(view) + ImageController::GEOMETRIES.keys
    actions.each { |dir| expire "#{RAILS_ROOT}/public/image/#{dir}/#{id}.*" }
    expire "#{RAILS_ROOT}/public/image/#{id}.*"
  end

  def expire(full_path)
    LOGGER.debug "delete #{full_path}"
    full_path = Dir.glob full_path if full_path =~ /\*$/
    rm_rf full_path
  end

end
