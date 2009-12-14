class AdminAssistant
  module Request
    class SingleCreate < Base
      def call
        saving = CreateSaving.new model_class.new, @controller
        if saving.record_and_associations_valid?
          saving.save
          saving.redirect_after_save
        else
          render_single_form saving.record
        end
      end
    end
    
    class MultiCreate < Base
      def call
        savings = ('a'..'j').map { |letter|
          CreateSaving.new(model_class.new, @controller, letter)
        }
        non_blank_savings = savings.reject &:blank?
        if non_blank_savings.map(&:record_and_associations_valid?).all?
          non_blank_savings.each do |s| s.save; end
          redirector = non_blank_savings.first || savings.first
          redirector.redirect_after_save
        else
          render_multi_form(
            savings.sort_by { |s| [(s.blank? ? 1 : 0), s.params_prefix] }.
                    map(&:record)
          )
        end
      end
    end
      
    class CreateSaving < Request::AbstractSaving
      attr_reader :params_prefix
      
      def initialize(record, controller, params_prefix = nil)
        super record, controller
        @params_prefix = params_prefix
      end
      
      def blank?
        raw_params.values.all? &:blank?
      end
      
      def params_for_save
        ParamsForSave.new @controller, @record, raw_params
      end
      
      def prepare_record_to_receive_invalid_association_assignments
        # no preparations necessary for creation
      end
      
      def raw_params
        model_class_symbol = @record.class.name.underscore.to_sym
        @controller.params[model_class_symbol][@params_prefix]
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
