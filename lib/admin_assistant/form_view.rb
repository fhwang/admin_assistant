class AdminAssistant
  class FormView
    def initialize(record, admin_assistant, action_view)
      @record, @admin_assistant, @action_view =
          record, admin_assistant, action_view
    end
    
    def action
      if %w(new create).include?(controller.action_name)
        'create'
      else
        'update'
      end
    end
    
    def after_column_html(column)
      if after = render_from_custom_template("_after_#{column.name}_input")
        after
      else
        helper_method = "after_#{column.name}_input"
        if @action_view.respond_to?(helper_method)
          @action_view.send(helper_method, @record)
        end
      end
    end
    
    def column_html(column, rails_form)
      hff = if (html = render_from_custom_template("_#{column.name}_input"))
        html
      else
        html_method = "#{column.name}_html_for_form"
        hff = if @action_view.respond_to?(html_method)
          @action_view.send(html_method, @record)
        end
        hff ||= if @admin_assistant.form_settings.read_only.include?(column.name)
          column.form_value(@record)
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
    
    def column_names
      @admin_assistant.form_settings.column_names ||
          @admin_assistant.model_class.columns.reject { |ar_column|
            %w(id created_at updated_at).include?(ar_column.name)
          }.map { |ar_column|
            @admin_assistant.column_name_or_assoc_name(ar_column.name)
          }
    end
    
    def columns
      @admin_assistant.columns(column_names).map { |c| c.view(@action_view) }
    end
    
    def controller
      @action_view.controller
    end
    
    def extra_submit_buttons
      @admin_assistant.form_settings.submit_buttons
    end
    
    def form_for_args
      args = {:url => {:action => action, :id => @record.id}}
      unless @admin_assistant.paperclip_attachments.empty?
        args[:html] = {:multipart => true}
      end
      args
    end
    
    def render_from_custom_template(slug)
      template = File.join(
        RAILS_ROOT, 'app/views', controller.controller_path, "#{slug}.html.erb"
      )
      if File.exist?(template)
        @action_view.render(
          :file => template,
          :locals => {
            @admin_assistant.model_class.name.underscore.to_sym => @record
          }
        )
      end
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
      fv = column.form_value @record
      if input_type
        if input_type == :check_box
          @action_view.send(:check_box_tag, input_name, '1', fv) +
              @action_view.send(:hidden_field_tag, input_name, '0')
        end
      else
        @action_view.send(:text_field_tag, input_name, fv)
      end
    end
  end
end
