class AdminAssistant
  class DefaultSearchColumn < Column
    def initialize(model_class)
      @model_class = model_class
    end
    
    def add_to_query_condition(ar_query_condition, search)
      unless search.params.blank?
        ar_query_condition.ar_query.boolean_join = :or
        AdminAssistant.searchable_columns(@model_class).each do |column|
          ar_query_condition.sqls << "#{column.name} like ?"
          ar_query_condition.bind_vars << "%#{search.params}%"
        end
      end
    end
    
    def attributes_for_search_object(search_params)
      {}
    end
      
    def search_view(action_view, opts={})
      View.new self, action_view
    end
    
    class View
      def initialize(column, action_view)
        @column, @action_view = column, action_view
      end
      
      def html(form)
        @action_view.text_field_tag("search", form.object.params)
      end
    end
  end
end
