require 'ar_query'

class AdminAssistant
  module ColumnsMethods
    def columns
      column_names = @admin_assistant.send(
        "#{self.class.name.split(/::/).last.downcase}_settings"
      ).column_names
      column_names = default_column_names unless column_names
      columns = paperclip_attachments.map { |paperclip_attachment|
        PaperclipColumn.new paperclip_attachment
      }
      column_names.each do |column_name|
        ar_column = @admin_assistant.model_class.columns_hash[column_name]
        if ar_column
          if columns.all? { |column| !column.contains?(ar_column) }
            columns << ActiveRecordColumn.new(ar_column)
          end
        else
          columns << AdminAssistantColumn.new(column_name)
        end
      end
      columns
    end
    
    def model_class
      @admin_assistant.model_class
    end
    
    def paperclip_attachments
      pa = []
      if model_class.respond_to?(:attachment_definitions)
        if model_class.attachment_definitions
          pa = model_class.attachment_definitions.map { |name, definition|
            name
          }
        end
      end
      pa
    end
  end
  
  class Index
    include ColumnsMethods
    
    def initialize(admin_assistant, url_params = {})
      @admin_assistant = admin_assistant
      @url_params = url_params
    end
    
    def default_column_names
      model_class.columns.map { |c| c.name }
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
        ar_query = ARQuery.new(
          :order => order_sql, :per_page => 25, :page => @url_params[:page]
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
    
    def sort_order
      @url_params[:sort_order] || 'asc'
    end
  end
end
