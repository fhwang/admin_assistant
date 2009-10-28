class AdminAssistant
  module Request
    class New < Base
      def call
        @record = model_class.new
        @admin_assistant.form_settings.columns_for_new.each do |column|
          if block = @admin_assistant.form_settings[column].default
            @record.send("#{column}=", block.call(@controller))
          end
        end
        if @controller.params[model_class_symbol]
          @record.attributes = params_for_save
        end
        render_form
      end
    end
  end
end
