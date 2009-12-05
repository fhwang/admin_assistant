class AdminAssistant
  module Request
    class Create < Base
      def call
        saving = Create::Saving.new model_class.new, @controller
        if saving.record_and_associations_valid?
          saving.save
          saving.redirect_after_save
        else
          render_form saving.record
        end
      end
      
      class Saving < Request::AbstractSaving 
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
end
