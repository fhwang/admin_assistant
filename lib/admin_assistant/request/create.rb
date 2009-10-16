class AdminAssistant
  module Request
    class Create < Base
      def call
        @record = model_class.new
        params = params_for_save
        if !params.errors.empty?
          @record.attributes = params
          @record.valid?
          valid = false
          params.errors.each do |attr, msg|
            @record.errors.add attr, msg
          end
        else
          @record.attributes = params
          valid = @record.valid?
        end
        if valid
          save
          redirect_after_save
        else
          @controller.instance_variable_set :@record, @record
          render_template_file 'form'
        end
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
