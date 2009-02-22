require File.expand_path(
  File.dirname(__FILE__) + '/../../vendor/ar_query/lib/ar_query'
)

class AdminAssistant
  class Index
    def initialize(model_class, url_params = {})
      @model_class = model_class
      @url_params = url_params
    end
    
    def next_sort_params(column_name)
      next_sort_order = 'asc'
      if @url_params[:sort] == column_name
        if sort_order == 'asc'
          next_sort_order = 'desc'
        else
          column_name = nil
          next_sort_order = nil
        end
      end
      {:sort => column_name, :sort_order => next_sort_order}
    end
    
    def order_sql
      if @url_params[:sort]
        "#{@url_params[:sort] } #{sort_order}"
      else
        'id desc'
      end
    end
    
    def records
      unless @records
        ar_query = ARQuery.new(:order => order_sql, :limit => 25)
        ar_query.boolean_join = :or
        if search_terms
          searchable_columns.each do |column|
            ar_query.condition_sqls << "#{column.name} like ?"
            ar_query.bind_vars << "%#{search_terms}%"
          end
        end
        @records = @model_class.find :all, ar_query
      end
      @records
    end
    
    def searchable_columns
      @model_class.columns.select { |column|
        [:string, :text].include?(column.type)
      }
    end
    
    def search_terms
      @url_params['search']
    end
    
    def sort_order
      @url_params[:sort_order] || 'asc'
    end
  end
end
