class AdminAssistant
  module Request
    class New < Base
      def call
        saving = Create::Saving.new model_class.new, @controller
        @admin_assistant.form_settings.columns_for_new.each do |column|
          if block = @admin_assistant.form_settings[column].default
            saving.record.send("#{column}=", block.call(@controller))
          end
        end
        if @controller.params[model_class_symbol]
          saving.record.attributes = saving.params_for_save
        end
        render_form saving.record
      end
    end
  end
end
