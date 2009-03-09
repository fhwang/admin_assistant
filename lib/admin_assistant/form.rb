class AdminAssistant
  class Form
    include ColumnsMethods

    def initialize(record, action, admin_assistant)
      @record, @action, @admin_assistant = record, action, admin_assistant
    end
    
    def default_column_names
      @admin_assistant.model_class.columns.reject { |ar_column|
        %w(id created_at updated_at).include?(ar_column.name)
      }.map { |ar_column| ar_column.name }
    end
    
    def extra_submit_buttons
      @admin_assistant.form_settings.submit_buttons
    end
    
    def form_for_args
      args = {:url => {:action => @action, :id => @record.id}}
      args[:html] = {:multipart => true} unless paperclip_attachments.empty?
      args
    end
    
    def submit_value
      @action.capitalize
    end
    
    def title
      (@record.id ? "Edit" : "New") + " #{@admin_assistant.model_class_name}"
    end
  end
end
