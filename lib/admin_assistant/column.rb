class AdminAssistant
  class Column
    attr_reader :custom_label, :match_text_fields, :search_comparator,
                :search_terms
    
    def initialize(opts)
      @custom_label = opts[:custom_label]
      @match_text_fields = opts[:match_text_fields]
      @search_comparator = opts[:search_comparator]
      @search_terms = opts[:search_terms]
    end
    
    def form_view(action_view, opts = {})
      view 'FormView', action_view, opts
    end
    
    def index_view(action_view, opts = {})
      view 'IndexView', action_view, opts
    end

    def search_view(action_view, opts = {})
      view 'SearchView', action_view, opts
    end
    
    def show_view(action_view, opts = {})
      view 'ShowView', action_view, opts
    end
    
    def view(view_class_name, action_view, opts)
      klass = self.class.const_get view_class_name
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
        unless %w(< <= = >= >).include?(@search_comparator)
          @search_comparator = nil
        end
        if @search_comparator
          ar_query_condition.sqls << "#{name} #{@search_comparator} ?"
          ar_query_condition.bind_vars << search_value
        else
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
      if !@match_text_fields && @search_terms
        @search_terms = @search_terms.to_i
      end
    end
    
    def add_to_query_condition(ar_query_condition)
      unless @search_terms.blank?
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
              sub_cond.bind_vars << "%#{@search_terms}%"
            end
          end
        elsif @search_terms.to_i != 0
          ar_query_condition.sqls << "#{association_foreign_key} = ?"
          ar_query_condition.bind_vars << @search_terms
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
    
    def search_value
      @search_terms
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
    
    def name; end
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
