class AdminAssistant
  class VirtualColumn < Column
    attr_reader :model_class, :name
    
    def initialize(name, model_class)
      @name, @model_class = name.to_s, model_class
    end
    
    def contains?(column_name)
      column_name.to_s == @name
    end
    
    class FormView < AdminAssistant::Column::View
      include AdminAssistant::Column::FormViewMethods
      
      def default_html(form)
        input_name = "#{@column.model_class.name.underscore}[#{name}]"
        if @input
          if @input == :check_box
            fv = value form.object
            # Rails 2.3 wants the hidden tag to come before the checkbox, but
            # it's the opposite for Rails 2.2 and 2.1
            if RAILS_GEM_VERSION =~ /^2.3/
              @action_view.send(:hidden_field_tag, input_name, '0') +
                  @action_view.send(:check_box_tag, input_name, '1', fv)
            else
              @action_view.send(:check_box_tag, input_name, '1', fv) +
                  @action_view.send(:hidden_field_tag, input_name, '0')
            end
          end
        else
          @action_view.send(:text_field_tag, input_name, string(form.object))
        end
      end
    end
  end
end
