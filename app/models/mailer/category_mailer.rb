class CategoryMailer < ActionMailer::Base

  def create(category)
    @category   = category
    #using a custom call instead of category.name since that call doesn't work at this point NameAlias DB entries are not written yet
    @subject    = "New Category '#{category.aliases.collect {|a| a.name if a.language.to_s == 'English'}.to_s}' Created"
    @body       = { :category => category }
    @recipients = 'category-core@omdb-beta.org'
    @from       = 'category-core@omdb-beta.org'
    @sent_on    = Time.now
    @headers    = {}
  end

end
