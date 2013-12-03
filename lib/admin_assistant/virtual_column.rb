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
    
    def attributes_for_search_object(search_params, compare_to_range)
      raw_value = search_params[@name.to_s]
      value = if raw_value == 'true'
        true
      elsif raw_value == 'false'
        false
      elsif raw_value.blank?
        nil
      else
        raw_value
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
        input = @input || :text_field
        html = if input == :check_box
          check_box_and_hidden_tags(input_name, value(object))
        else
          @action_view.send("#{input}_tag", input_name, string(object))
        end
        if has_matching_errors?(object)
          html = "<div class=\"field_with_errors\">#{html}</div>"
        end
        html
      end
      
      def has_matching_errors?(record)
        record.respond_to?(:errors) && record.errors.respond_to?(:[]) && 
           record.errors[name]
      end
    end
    
    class SearchView < AdminAssistant::Column::View
      include AdminAssistant::Column::SimpleColumnSearchViewMethods
    end
  end
end
