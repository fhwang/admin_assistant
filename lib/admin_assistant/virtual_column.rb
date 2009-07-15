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
            check_box_and_hidden_tags(input_name, fv)
          end
        else
          @action_view.send(:text_field_tag, input_name, string(form.object))
        end
      end
    end
  end
end
