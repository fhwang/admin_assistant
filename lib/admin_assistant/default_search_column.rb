class AdminAssistant
  class DefaultSearchColumn < Column
    def initialize(model_class, opts)
      @model_class = model_class
      @fields_to_include = opts[:fields_to_include] || []
    end
    
    def add_to_query_condition(ar_query_condition, search)
      unless search.params.blank?
        ar_query_condition.ar_query.boolean_join = :and
        ar_query_condition.boolean_join = :or
        names_to_search = Model.new(@model_class).searchable_columns.map(
          &:name
        )
        names_to_search.concat @fields_to_include
        names_to_search.uniq.each do |field_name|
          ar_query_condition.sqls << "LOWER(#{field_name}) like LOWER(?)"
          ar_query_condition.bind_vars << "%#{search.params}%"
        end
      end
    end
    
    def attributes_for_search_object(search_params)
      {}
    end
      
    def search_view(action_view, admin_assistant, opts={})
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
