class MovieMailer < ActionMailer::Base

  def create(movie)
    @subject    = "The Movie '#{movie.name}' has been created"
    @body       = { :movie => movie }
    @recipients = 'new-movies@omdb.org'
    @from       = 'new-movies@omdb.org'
    @sent_on    = Time.now
    @headers    = {}
  end

end
