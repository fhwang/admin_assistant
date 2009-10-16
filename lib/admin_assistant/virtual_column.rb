class AdminAssistant
  class VirtualColumn < Column
    attr_reader :model_class, :name
    
    def initialize(name, model_class, admin_assistant)
      @name, @model_class = name.to_s, model_class
      @search_settings = admin_assistant.search_settings[name]
    end
    
    def add_to_query_condition(ar_query_condition, search)
      if conditions = @search_settings.conditions.call(search.send(@name))
        ar_query_condition.sqls << conditions
      end
    end
    
    def attributes_for_search_object(search_params)
      value = if search_params[@name.to_s] == 'true'
        true
      elsif search_params[@name.to_s] == 'false'
        false
      else
        nil
      end
      {@name => value}
    end
    
    def contains?(column_name)
      column_name.to_s == @name
    end
    
    def field_type
      @search_settings.field_type
    end
    
    def verify_for_search
      unless @search_settings.conditions
        raise "Virtual search column #{@name.to_sym.inspect} needs a conditions block"
      end
    end
    
    class FormView < AdminAssistant::Column::View
      include AdminAssistant::Column::FormViewMethods
      
      def default_html(form)
        object = form.object
        input_name = "#{@column.model_class.name.underscore}[#{name}]"
        html = if @input
          if @input == :check_box
            fv = value form.object
            check_box_and_hidden_tags(input_name, fv)
          end
        else
          @action_view.send(:text_field_tag, input_name, string(form.object))
        end
        if object.respond_to?(:errors) && object.errors.respond_to?(:on) && 
           object.errors.on(name)
          html = "<div class=\"fieldWithErrors\">#{html}</div>"
        end
        html
      end
    end
    
    class SearchView < AdminAssistant::Column::View
      include AdminAssistant::Column::SimpleColumnSearchViewMethods
    end
  end
end
