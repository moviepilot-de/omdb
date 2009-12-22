class MovieObserver < ActiveRecord::Observer

  def after_create(movie)
    if movie.base_class_name == "Movie"
      MovieMailer.template_root = "#{RAILS_ROOT}/app/views/mail_templates"
      MovieMailer.deliver_create movie
    end
    # hack, ohne '.html' wuerde kompletter movie-controller-cache geloescht werden
    PageCacheSweeper.instance.delete 'movie.html'
  end
end
