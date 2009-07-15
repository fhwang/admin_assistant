class AdminAssistant
  module Request
    class Destroy < Base
      def call
        @record = model_class.find @controller.params[:id]
        if @admin_assistant.custom_destroy
          @admin_assistant.custom_destroy.call @record
        else
          @record.destroy
        end
        @controller.send :render, :text => ''
      end
    end
  end
end
