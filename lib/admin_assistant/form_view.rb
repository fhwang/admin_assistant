class AdminAssistant
  class FormView
    include ColumnsMethods

    def initialize(record, admin_assistant, view)
      @record, @admin_assistant, @view = record, admin_assistant, view
    end
    
    def action
      if %w(new create).include?(controller.action_name)
        'create'
      else
        'update'
      end
    end
    
    def after_column_html(column)
      after_html_template = File.join(
        RAILS_ROOT, 'app/views', controller.controller_path,
        "_after_#{column.name}_input.html.erb"
      )
      if File.exist?(after_html_template)
        @view.render(
          :file => after_html_template,
          :locals => {
            @admin_assistant.model_class.name.underscore.to_sym => @record
          }
        )
      else
        helper_method = "after_#{column.name}_input"
        @view.send(helper_method, @record) if @view.respond_to?(helper_method)
      end
    end
    
    def column_html(column, rails_form)
      template = File.join(
        RAILS_ROOT, 'app/views', controller.controller_path,
        "_#{column.name}_input.html.erb"
      )
      hff = if File.exist?(template)
        @view.render(
          :file => template,
          :locals => {
            @admin_assistant.model_class.name.underscore.to_sym => @record
          }
        )
      else
        html_method = "#{column.name}_html_for_form"
        hff = @view.respond_to?(html_method) && @view.send(html_method, @record)
        hff ||= if @admin_assistant.form_settings.read_only.include?(column.name)
          @view.send(:field_value, @record, column)
        elsif column.respond_to?(:add_to_form)
          column.add_to_form(rails_form)
        else
          virtual_column_html column
        end
      end
      if ah = after_column_html(column)
        hff << ah
      end
      hff
    end
    
    def controller
      @view.controller
    end
    
    def default_column_names
      @admin_assistant.model_class.columns.reject { |ar_column|
        %w(id created_at updated_at).include?(ar_column.name)
      }.map { |ar_column| column_name_or_assoc_name(ar_column.name) }
    end
    
    def extra_submit_buttons
      @admin_assistant.form_settings.submit_buttons
    end
    
    def form_for_args
      args = {:url => {:action => action, :id => @record.id}}
      args[:html] = {:multipart => true} unless paperclip_attachments.empty?
      args
    end
    
    def submit_value
      action.capitalize
    end
    
    def title
      (@record.id ? "Edit" : "New") + " #{@admin_assistant.model_class_name}"
    end
    
    def virtual_column_html(column)
      input_name =
          "#{@admin_assistant.model_class.name.underscore}[#{column.name}]"
      input_type = @admin_assistant.form_settings.inputs[column.name.to_sym]
      fv = @view.send(:field_value, @record, column)
      if input_type
        if input_type == :check_box
          @view.send(:check_box_tag, input_name, '1', fv) +
              @view.send(:hidden_field_tag, input_name, '0')
        end
      else
        @view.send(:text_field_tag, input_name, fv)
      end
    end
  end
end
