class Abstract < Content
  
  validates_length_of :data,
                      :if => Proc.new { |abs| abs.data.chars.length > 400 },
                      :maximum => 400,
                      :message => "please don't use more then 400 characters"

  def display_title
    "Abstract"
  end

  # overridden from ar_base_ext
  def default_url(*args)
    related_object.default_url 'index'
  end
  
end
