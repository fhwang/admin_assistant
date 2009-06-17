class AdminAssistant
  class Search
    def initialize(admin_assistant, search_params)
      @admin_assistant, @search_params = admin_assistant, search_params
      @search_params ||= {}
    end
    
    def [](name)
      @search_params[name]
    end
  
    def add_to_query(ar_query)
      unless @search_params.empty?
        ar_query.add_condition do |cond|
          if match_any_conditions?
            cond.boolean_join = :or
          end
          columns.each do |column|
            column.add_to_query_condition cond
          end
        end
      end
    end
    
    def columns
      column_names = settings.column_names
      if column_names.empty?
        [DefaultSearchColumn.new(
          (@search_params if @search_params.is_a?(String)),
          @admin_assistant.model_class
        )]
      else
        columns = column_names.map { |column_name|
          column = @admin_assistant.column column_name.to_s
          klass_name = column.class.name.gsub(
            /^(.*)::([^:]*)Column$/, '\2SearchColumn'
          )
          klass = AdminAssistant::Search.const_get klass_name
          klass.new(
            column, @search_params,
            settings[column_name.to_sym].match_text_fields_for_association?
          )
        }
        columns
      end
    end
    
    def column_views(action_view)
      columns.map { |c|
        opts = {:search => self}
        if c.respond_to?(:name) && c.name
          opts[:boolean_labels] =
              @admin_assistant.index_settings[c.name].boolean_labels
          opts[:label] = @admin_assistant.custom_column_labels[c.name]
        end
        c.view action_view, opts
      }
    end
    
    def id
    end
    
    def match_all_conditions?
      !match_any_conditions?
    end
    
    def match_any_conditions?
      @search_params["(all_or_any)"] == 'any'
    end
    
    def method_missing(meth, *args)
      column = columns.detect { |c| c.name == meth.to_s }
      if column
        column.value_for_search_object
      else
        column = columns.detect { |c|
          c.respond_to?(:association_foreign_key ) &&
          c.association_foreign_key == meth.to_s 
        }
        if column
          column.value_for_query
        else
          super
        end
      end
    end
  
    def settings
      @admin_assistant.search_settings
    end
    
    class SearchColumn < SimpleDelegator
      attr_reader :match_text_fields
      
      def initialize(column, search_params, match_text_fields)
        super column
        @column, @search_params, @match_text_fields =
            column, search_params, match_text_fields
      end
      
      def comparator
        @search_params["#{@column.name}(comparator)"]
      end

      def view(action_view, opts = {})
        klass = @column.class.const_get 'SearchView'
        klass.new self, action_view, opts
      end
    end
    
    class ActiveRecordSearchColumn < SearchColumn
      def add_to_query_condition(ar_query_condition)
        unless value_for_query.nil?
          comp = comparator
          unless %w(< <= = >= >).include?(comparator)
            comp = nil
          end
          if comp
            ar_query_condition.sqls << "#{name} #{comp} ?"
            ar_query_condition.bind_vars << value_for_query
          else
            case sql_type
              when :boolean
                ar_query_condition.sqls << "#{name} = ?"
                ar_query_condition.bind_vars << value_for_query
              else
                ar_query_condition.sqls << "#{name} like ?"
                ar_query_condition.bind_vars << "%#{value_for_query}%"
            end
          end
        end
      end
      
      def value_for_search_object
        value_for_query
      end
    
      def value_for_query
        terms = @search_params[@column.name]
        unless terms.blank?
          case sql_type
            when :boolean
              terms.blank? ? nil : (terms == 'true')
            else
              terms
          end
        end
      end
    end
    
    class BelongsToSearchColumn < SearchColumn
      def add_to_query_condition(ar_query_condition)
        if value_for_query
          if @match_text_fields
            ar_query_condition.ar_query.joins << name.to_sym
            searchable_columns = AdminAssistant.searchable_columns(
              associated_class
            )
            ar_query_condition.add_condition do |sub_cond|
              sub_cond.boolean_join = :or
              searchable_columns.each do |column|
                sub_cond.sqls <<
                    "#{associated_class.table_name}.#{column.name} like ?"
                sub_cond.bind_vars << "%#{value_for_query}%"
              end
            end
          elsif value_for_query
            ar_query_condition.sqls << "#{association_foreign_key} = ?"
            ar_query_condition.bind_vars << value_for_query
          end
        end
      end
      
      def value_for_search_object
        associated_class.find(value_for_query) if value_for_query
      end
    
      def value_for_query
        if @match_text_fields
          @search_params[@column.name]
        else
          terms = @search_params[@column.association_foreign_key]
          terms.to_i unless terms.blank?
        end
      end
    end
  
    class DefaultSearchColumn
      attr_reader :terms
      
      def initialize(terms, model_class)
        @terms, @model_class = terms, model_class
      end
      
      def add_to_query_condition(ar_query_condition)
        unless @terms.blank?
          ar_query_condition.ar_query.boolean_join = :or
          AdminAssistant.searchable_columns(@model_class).each do |column|
            ar_query_condition.sqls << "#{column.name} like ?"
            ar_query_condition.bind_vars << "%#{@terms}%"
          end
        end
      end
      
      def view(action_view, opts={})
        View.new self, action_view
      end
      
      class View
        def initialize(column, action_view)
          @column, @action_view = column, action_view
        end
        
        def html
          @action_view.text_field_tag("search", @column.terms)
        end
      end
    end
  end
end
