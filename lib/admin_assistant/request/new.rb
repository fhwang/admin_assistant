class AdminAssistant
  module Request
    class AbstractNew < Base
      def new_saving
        saving = CreateSaving.new model_class.new, @controller
        @admin_assistant.form_settings.columns_for_new.each do |column|
          if block = @admin_assistant.form_settings[column].default
            saving.record.send("#{column}=", block.call(@controller))
          end
        end
        if @controller.params[model_class_symbol]
          saving.record.attributes = saving.params_for_save
        end
        saving
      end
    end
    
    class SingleNew < AbstractNew
      def call
        render_single_form new_saving.record
      end
    end
    
    class MultiNew < AbstractNew
      def call
        records = (0..9).map { new_saving }.map(&:record)
        render_multi_form records
      end
    end
  end
end
