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
    
    def column_names
      if %w(new create).include?(@action_view.action_name)
        settings.columns_for_new
      elsif %w(edit update).include?(@action_view.action_name)
        settings.columns_for_edit
      end
    end
    
    def columns
      @admin_assistant.accumulate_columns(column_names).map { |c|
        c.form_view @action_view, @admin_assistant
      }
    end
    
    def controller
      @action_view.controller
    end
    
    def extra_submit_buttons
      settings.submit_buttons
    end
    
    def form_for_args
      args = {:url => {:action => action, :id => @record.id}}
      unless @admin_assistant.paperclip_attachments.empty? &&
             @admin_assistant.file_columns.empty?
        args[:html] = {:multipart => true}
      end
      args
    end
    
    def model_class
      @admin_assistant.model_class
    end
    
    def settings
      @admin_assistant.form_settings
    end
    
    def submit_value
      action.capitalize
    end
    
    def title
      (@record.id ? "Edit" : "New") + " #{@admin_assistant.model_class_name}"
    end
  end
end
