class AdminAssistant
  class HasManyColumn < Column
    def initialize(has_many_assoc, opts)
      @has_many_assoc = has_many_assoc
      @match_text_fields_in_search = opts[:match_text_fields_in_search]
    end
    
    def add_to_query_condition(ar_query_condition, search)
      if @match_text_fields_in_search
        if (value = search.send(name)) and !value.blank?
          searchable_columns = Model.new(associated_class).searchable_columns
          model_class = @has_many_assoc.active_record
          sanitized_match_value = ActiveRecord::Base.sanitize("%#{value}%")
          searchable_column_comparisons = searchable_columns.map { |column|
            "LOWER(#{associated_class.table_name}.#{column.name}) like LOWER(#{sanitized_match_value})"
          }
          condition_sql = <<-CONDITION_SQL
          #{model_class.table_name}.#{model_class.primary_key} in (select #{@has_many_assoc.primary_key_name} from #{associated_class.table_name} where #{searchable_column_comparisons.join(' or ')})
          CONDITION_SQL
          ar_query_condition.sqls << condition_sql
        end
      end
    end

    def associated_class
      @has_many_assoc.klass
    end
    
    def attributes_for_search_object(search_params, compare_to_range)
      {name.to_sym => search_params[name]}
    end
    
    def contains?(column_name)
      column_name.to_s == name
    end
    
    def model_class
      @has_many_assoc.active_record
    end
    
    def name
      @has_many_assoc.name.to_s
    end
    
    class FormView < AdminAssistant::VirtualColumn::FormView
    end
    
    class SearchView < AdminAssistant::Column::View
      include AdminAssistant::Column::SearchViewMethods
      
      def html(form)
        "<p><label>#{label}</label> <br/>#{form.text_field(name)}</p>"
      end
    end
  end
end
