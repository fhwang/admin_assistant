class AdminAssistant
  class ShowView
    def initialize(record, admin_assistant, action_view)
      @record, @admin_assistant, @action_view =
          record, admin_assistant, action_view
    end
    
    def column_html(column)
      column.html @record
    end
    
    def columns
      column_names = @admin_assistant.show_settings.column_names || 
                     @admin_assistant.model_class.columns.map(&:name)
      @admin_assistant.accumulate_columns(column_names).map { |c|
        c.show_view @action_view, @admin_assistant
      }
    end
  end
end
