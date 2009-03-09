class AdminAssistant
  module Helper
    def admin_assistant_includes
      stylesheet_link_tag 'admin_assistant'
    end
    
    def after_html_for_form(column, record)
      after_html_template = File.join(
        RAILS_ROOT, 'app/views', controller.controller_path,
        "_after_#{column.name}_input.html.erb"
      )
      if File.exist?(after_html_template)
        render(
          :file => after_html_template,
          :locals => {
            @admin_assistant.model_class.name.underscore.to_sym => record
          }
        )
      else
        helper_method = "after_#{column.name}_input"
        self.send(helper_method, record) if respond_to?(helper_method)
      end
    end
    
    def controller_css_class
      controller.controller_path.gsub(%r|/|, '_')
    end
    
    def field_value(record, column)
      value_method = "#{column.name}_value"
      fv = if respond_to?(value_method)
        self.send value_method, record
      else
        column.field_value record
      end
      fv
    end
    
    def html_for_form_column_and_record(column, record)
      input_name =
          "#{@admin_assistant.model_class.name.underscore}[#{column.name}]"
      input_type = @admin_assistant.form_settings.inputs[column.name.to_sym]
      if input_type
        if input_type == :check_box
          check_box_tag(input_name, '1', field_value(record, column)) +
              hidden_field_tag(input_name, '0')
        end
      else
        text_field_tag(input_name, field_value(record, column))
      end
    end
    
    def html_for_form(column, record, form)
      template = File.join(
        RAILS_ROOT, 'app/views', controller.controller_path,
        "_#{column.name}_input.html.erb"
      )
      hff = if File.exist?(template)
        render(
          :file => template,
          :locals => {
            @admin_assistant.model_class.name.underscore.to_sym => record
          }
        )
      else
        html_method = "#{column.name}_html_for_form"
        hff = respond_to?(html_method) && self.send(html_method, record)
        hff ||= if column.respond_to?(:add_to_form)
          column.add_to_form(form)
        else
          html_for_form_column_and_record column, record
        end
      end
      if ah = after_html_for_form(column, record)
        hff << ah
      end
      hff
    end
    
    def html_for_index(column, record)
      html_for_index_method = "#{column.name}_html_for_index"
      hfi = if respond_to?(html_for_index_method)
        self.send html_for_index_method, record
      elsif column.is_a?(PaperclipColumn)
        image_tag(record.send(column.name).url)
      else
        value = field_value(record, column)
        if column.respond_to?(:sql_type) && column.sql_type == :boolean
          custom = @admin_assistant.index_settings.boolean_labels[column.name]
          if custom
            value = value ? custom.first : custom.last
          end
        end
        h value
      end
      hfi = '&nbsp;' if hfi.blank?
      hfi
    end
  end
end
