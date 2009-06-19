class AdminAssistant
  class Column
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
    def initialize(ar_column)
      @ar_column = ar_column
    end
    
    def add_to_query_condition(ar_query_condition, search)
      value_for_query = value_for_search_object search.params
      unless value_for_query.nil?
        comp = comparator(search)
        unless %w(< <= = >= >).include?(comp)
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
      
    def comparator(search)
      search.params["#{@ar_column.name}(comparator)"]
    end
    
    def contains?(column_name)
      column_name.to_s == @ar_column.name
    end
    
    def name
      @ar_column.name
    end
    
    def sql_type
      @ar_column.type
    end
      
    def value_for_search_object(search_params)
      terms = search_params[@ar_column.name]
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
  
  class AdminAssistantColumn < Column
    attr_reader :name
    
    def initialize(name)
      @name = name.to_s
    end
    
    def contains?(column_name)
      column_name.to_s == @name
    end
  end
  
  class BelongsToColumn < Column
    attr_reader :match_text_fields_in_search
    
    def initialize(belongs_to_assoc, opts)
      @belongs_to_assoc = belongs_to_assoc
      @match_text_fields_in_search = opts[:match_text_fields_in_search]
      @association_target = AssociationTarget.new associated_class
    end
    
    def add_to_query_condition(ar_query_condition, search)
      if @match_text_fields_in_search
        if value = search.send(name)
          ar_query_condition.ar_query.joins << name.to_sym
          searchable_columns = AdminAssistant.searchable_columns(
            associated_class
          )
          ar_query_condition.add_condition do |sub_cond|
            sub_cond.boolean_join = :or
            searchable_columns.each do |column|
              sub_cond.sqls <<
                  "#{associated_class.table_name}.#{column.name} like ?"
              sub_cond.bind_vars << "%#{value}%"
            end
          end
        end
      elsif value = search.send(association_foreign_key)
        ar_query_condition.sqls << "#{association_foreign_key} = ?"
        ar_query_condition.bind_vars << value
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
      @association_target.default_name_method
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
    
    def options_for_select
      @association_target.options_for_select
    end
      
    def value_for_search_object(search_params)
      if @match_text_fields_in_search
        search_params[name]
      else
        terms = search_params[association_foreign_key]
        associated_id = terms.to_i unless terms.blank?
        if associated_id
          associated_class.find(associated_id)
        end
      end
    end
  end
  
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
  
  class FileColumnColumn < Column
    attr_reader :name
    
    def initialize(name)
      @name = name.to_s
    end
    
    def contains?(column_name)
      column_name.to_s == @name
    end
  end
  
  class PaperclipColumn < Column
    attr_reader :name
    
    def initialize(name)
      @name = name.to_s
    end
    
    def contains?(column_name)
      column_name.to_s == @name ||
      column_name.to_s =~
          /^#{@name}_(file_name|content_type|file_size|updated_at)$/
    end
  end
  
  class PolymorphicBelongsToColumn < Column
    def initialize(belongs_to_assoc)
      @belongs_to_assoc = belongs_to_assoc
    end
    
    def association_foreign_key
      @belongs_to_assoc.association_foreign_key
    end
    
    def contains?(column_name)
      column_name.to_s == name
    end
    
    def name
      @belongs_to_assoc.name.to_s
    end
  end
  
  class AssociationTarget
    def initialize(associated_class)
      @associated_class = associated_class
    end
    
    def default_name_method
      [:name, :title, :login, :username].detect { |m|
        @associated_class.columns.any? { |column| column.name.to_s == m.to_s }
      }
    end
      
    def options_for_select
      @associated_class.
          find(:all).
          sort_by { |model| model.send(default_name_method) }.
          map { |model| [model.send(default_name_method), model.id] }
    end
  end
end
