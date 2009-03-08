require 'ar_query'

class AdminAssistant
  class Index
    include ColumnsMethods
    
    def initialize(admin_assistant, url_params = {})
      @admin_assistant = admin_assistant
      @url_params = url_params
    end
    
    def belongs_to_sort_column
      columns.detect { |c|
        c.belongs_to_assoc && 
            c.belongs_to_assoc.name.to_s == @url_params[:sort]
      }
    end
    
    def columns
      c = columns_without_options
      if sort
        c.each do |column|
          column.sort_order = sort_order if column.name == sort
        end
      end
      c
    end
    
    def default_column_names
      model_class.columns.map { |c| c.name }
    end
    
    def find_include
      if by_assoc = belongs_to_sort_column
        by_assoc.belongs_to_assoc.name
      end
    end
    
    def next_sort_params(column)
      name_for_sort = column.name_for_sort
      next_sort_order = 'asc'
      if @url_params[:sort] == name_for_sort
        if sort_order == 'asc'
          next_sort_order = 'desc'
        else
          name_for_sort = nil
          next_sort_order = nil
        end
      end
      {:sort => name_for_sort, :sort_order => next_sort_order}
    end
    
    def order_sql
      if @url_params[:sort]
        sort_column = columns.detect { |c| c.name.to_s == @url_params[:sort] }
        first_part = if sort_column
          sort_column.name
        else
          by_assoc = belongs_to_sort_column
          belongs_to = by_assoc.belongs_to_assoc
          if by_assoc.default_name_method
            "#{belongs_to.table_name}.#{by_assoc.default_name_method}"
          else
            "#{belongs_to.table_name}.#{belongs_to.association_foreign_key}"
          end
        end
        "#{first_part} #{sort_order}"
      else
        @admin_assistant.index_settings.sort_by
      end
    end
    
    def records
      unless @records
        ar_query = ARQuery.new(
          :order => order_sql, :include => find_include,
          :per_page => 25, :page => @url_params[:page]
        )
        ar_query.boolean_join = :or
        if search_terms
          searchable_columns.each do |column|
            ar_query.condition_sqls << "#{column.name} like ?"
            ar_query.bind_vars << "%#{search_terms}%"
          end
        end
        if @admin_assistant.index_settings.conditions
          conditions =
              @admin_assistant.index_settings.conditions.call(@url_params)
          ar_query.condition_sqls << conditions if conditions
        end
        @records = model_class.paginate :all, ar_query
      end
      @records
    end
    
    def searchable_columns
      model_class.columns.select { |column|
        [:string, :text].include?(column.type)
      }
    end
    
    def search_terms
      @url_params['search']
    end
    
    def sort
      @url_params[:sort]
    end
    
    def sort_order
      @url_params[:sort_order] || 'asc'
    end
    
    def sort_possible?(column)
      column.is_a?(ActiveRecordColumn)
    end
  end
end
