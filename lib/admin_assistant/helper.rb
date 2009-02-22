class AdminAssistant
  module Helper
    def after_html_for_form(column, record)
      after_html_template = File.join(
        RAILS_ROOT, 'app/views', controller.controller_path,
        "_after_#{column.name}_html_for_form.html.erb"
      )
      if File.exist?(after_html_template)
        render(
          :file => after_html_template,
          :locals => {
            @admin_assistant.model_class.name.underscore.to_sym => record
          }
        )
      end
    end
    
    def field_value(record, column)
      value_method = "#{column.name}_value"
      if respond_to?(value_method)
        self.send value_method, record
      else
        record.send column.name
      end
    end
    
    def html_for_index(column, record)
      html_for_index_method = "#{column.name}_html_for_index"
      if respond_to?(html_for_index_method)
        self.send html_for_index_method, record
      else
        h(field_value(record, column))
      end
    end
    
    def html_for_form(column, record, form)
      html_method = "#{column.name}_html_for_form"
      hff = if respond_to?(html_method)
        self.send(html_method, record)
      elsif column.is_a?(ActiveRecordColumn)
        case column.type
          when :text
            form.text_area column.name
          else
            form.text_field column.name
          end
      else
        text_field_tag(
          "#{@admin_assistant.model_class.name.underscore}[#{column.name}]",
          field_value(record, column)
        )
      end
      if ah = after_html_for_form(column, record)
        hff << ah
      end
      hff
    end
  end
end
