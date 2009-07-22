class AdminAssistant
  module Request
    class Show < Base
      def call
        @record = model_class.find @controller.params[:id]
        @controller.instance_variable_set :@record, @record
        @controller.send(
          :render,
          :file => AdminAssistant.template_file('show'), :layout => true,
          :locals => {:request => self}
        )
      end
      
      def model_class_name(record)
        if block = @admin_assistant.show_settings.model_class_name_block
          block.call record
        else
          @admin_assistant.model_class_name
        end
      end
    end
  end
end

