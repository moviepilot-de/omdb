class CategoryObserver < ActiveRecord::Observer

  def after_create(category)
    category.logger.warn("Category created: #{category}")
    if category.class == Category
      CategoryMailer.template_root = "#{RAILS_ROOT}/app/views/mail_templates"
      # CategoryMailer.deliver_create category
    end
  end
end
