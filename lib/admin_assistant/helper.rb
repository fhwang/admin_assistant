class AdminAssistant
  module Helper
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
      if respond_to?(html_method)
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
    end
  end
end
