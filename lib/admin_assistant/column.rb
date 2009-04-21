class AdminAssistant
  class Column
    attr_reader :custom_label, :search_terms
    
    def initialize(opts)
      @custom_label = opts[:custom_label]
      @search_terms = opts[:search_terms]
    end
    
    def form_view(action_view, opts = {})
      klass = self.class.const_get 'FormView'
      klass.new self, action_view, opts
    end
    
    def index_view(action_view, opts = {})
      klass = self.class.const_get 'IndexView'
      klass.new self, action_view, opts
    end

    def search_view(action_view, opts = {})
      klass = self.class.const_get 'SearchView'
      klass.new self, action_view, opts
    end
  end
  
  class ActiveRecordColumn < Column
    def initialize(ar_column, opts)
      super opts
      @ar_column = ar_column
    end
    
    def add_to_query_condition(ar_query_condition)
      unless @search_terms.blank?
        case sql_type
          when :boolean
            ar_query_condition.sqls << "#{name} = ?"
            ar_query_condition.bind_vars << search_value
          else
            ar_query_condition.sqls << "#{name} like ?"
            ar_query_condition.bind_vars << "%#{@search_terms}%"
        end
      end
    end
    
    def contains?(column_name)
      column_name.to_s == @ar_column.name
    end
    
    def name
      @ar_column.name
    end
    
    def search_value
      case sql_type
        when :boolean
          @search_terms.blank? ? nil : (@search_terms == 'true')
        else
          @search_terms
      end
    end
    
    def sql_type
      @ar_column.type
    end
  end
  
  class AdminAssistantColumn < Column
    attr_reader :name
    
    def initialize(name, opts)
      super opts
      @name = name.to_s
    end
    
    def contains?(column_name)
      column_name.to_s == @name
    end
  end
  
  class BelongsToColumn < Column
    attr_reader :search_terms
    
    def initialize(belongs_to_assoc, opts)
      super opts
      @belongs_to_assoc = belongs_to_assoc
    end
    
    def add_to_query_condition(ar_query_condition)
      unless @search_terms.blank?
        ar_query_condition.ar_query.joins << name.to_sym
        ar_query_condition.add_condition do |sub_cond|
          sub_cond.boolean_join = :or
          AdminAssistant.searchable_columns(associated_class).each do |column|
            sub_cond.sqls <<
                "#{associated_class.table_name}.#{column.name} like ?"
            sub_cond.bind_vars << "%#{@search_terms}%"
          end
        end
      end
    end
    
    def associated_class
      @belongs_to_assoc.klass
    end
    
    def association_foreign_key
      @belongs_to_assoc.association_foreign_key
    end
    
    def contains?(column_name)
      column_name.to_s == name
    end
    
    def default_name_method
      [:name, :title, :login, :username].detect { |m|
        associated_class.columns.any? { |column| column.name.to_s == m.to_s }
      }
    end
    
    def name
      @belongs_to_assoc.name.to_s
    end
    
    def order_sql_field
      sql = "#{@belongs_to_assoc.table_name}. "
      sql << if default_name_method
        default_name_method.to_s
      else
        @belongs_to_assoc.association_foreign_key
      end
    end
  end
  
  class DefaultSearchColumn < Column
    def initialize(terms, model_class)
      super({:search_terms => terms})
      @model_class = model_class
    end
    
    def add_to_query_condition(ar_query_condition)
      unless @search_terms.blank?
        ar_query_condition.ar_query.boolean_join = :or
        AdminAssistant.searchable_columns(@model_class).each do |column|
          ar_query_condition.sqls << "#{column.name} like ?"
          ar_query_condition.bind_vars << "%#{@search_terms}%"
        end
      end
    end
  end
  
  class FileColumnColumn < Column
    attr_reader :name
    
    def initialize(name, opts)
      super opts
      @name = name.to_s
    end
    
    def contains?(column_name)
      column_name.to_s == @name
    end
  end
  
  class PaperclipColumn < Column
    attr_reader :name
    
    def initialize(name, opts = {})
      super opts
      @name = name.to_s
    end
    
    def contains?(column_name)
      column_name.to_s == @name ||
      column_name.to_s =~
          /^#{@name}_(file_name|content_type|file_size|updated_at)$/
    end
  end
end
