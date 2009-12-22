# don't render <div class="error"> around fields with errors:
ActionView::Base.field_error_proc = Proc.new { |html_tag, instance| html_tag }

 
class LabelledFormBuilder < ActionView::Helpers::FormBuilder
  (field_helpers - %w(check_box radio_button hidden_field)).each do |selector|
    src = <<-END_SRC
    def #{selector}(field, options = {})
      err_msg = ''
      img = ''
      if object && errors = object.errors.on(field.to_s)
        css_class = 'error'
        errors = [errors] unless errors.respond_to?(:join)
        err_msg = ' <em>' << errors.select { |e| !e.empty? }.join('</em>, <em>') << '</em>'
      end
      content = super + err_msg
      unless (label = options.delete(:label)) == :none
        label_id = object_name.to_s << '_' << field.to_s
        content = @template.content_tag( "label", 
                                         (label || '').t + (options.delete(:required) ? '*':''),
                                         :for => label_id, 
                                         :class => (options.delete(:required) ? 'required':'')) +
                  content
      end
      @template.content_tag("p", content, :class => css_class.to_s)
    end
    END_SRC
    class_eval src, __FILE__, __LINE__
  end
end


