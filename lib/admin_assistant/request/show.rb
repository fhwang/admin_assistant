class AdminAssistant
  module Request
    class Show < Base
      def call
        @record = model_class.find @controller.params[:id]
        @controller.instance_variable_set :@record, @record
        @controller.send(
          :render,
          :file => AdminAssistant.template_file('show'), :layout => true
        )
      end
    end
  end
end

