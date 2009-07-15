class AdminAssistant
  module Request
    class Edit < Base
      def call
        @record = model_class.find @controller.params[:id]
        @controller.instance_variable_set :@record, @record
        render_template_file 'form'
      end
    end
  end
end
