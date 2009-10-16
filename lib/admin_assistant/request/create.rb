class AdminAssistant
  module Request
    class Create < Base
      include Save
      
      def call
        @record = model_class.new
        if record_and_associations_valid?
          save
          redirect_after_save
        else
          @controller.instance_variable_set :@record, @record
          render_template_file 'form'
        end
      end
      
      def prepare_record_to_receive_invalid_association_assignments
        # no preparations necessary for creation
      end
      
      def save
        if @controller.respond_to?(:before_create)
          @controller.send(:before_create, @record)
        end
        result = super
        if @controller.respond_to?(:after_create)
          @controller.send(:after_create, @record)
        end
        result
      end
    end
  end
end
