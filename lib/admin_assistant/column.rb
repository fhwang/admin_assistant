class AdminAssistant
  class Column
    def form_view(action_view, opts = {})
      view 'FormView', action_view, opts
    end
    
    def index_view(action_view, opts = {})
      view 'IndexView', action_view, opts
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
    
    def contains?(column_name)
      column_name.to_s == @ar_column.name
    end
    
    def name
      @ar_column.name
    end
    
    def sql_type
      @ar_column.type
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
    attr_reader :search_terms
    
    def initialize(belongs_to_assoc)
      @belongs_to_assoc = belongs_to_assoc
      if !@match_text_fields && @search_terms
        @search_terms = @search_terms.to_i
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
    
    def polymorphic?
      @belongs_to_assoc.options[:polymorphic]
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
end
