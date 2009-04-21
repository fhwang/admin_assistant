require 'ar_query'

class AdminAssistant
  class Index
    def initialize(admin_assistant, url_params = {})
      @admin_assistant = admin_assistant
      @url_params = url_params
    end
    
    def belongs_to_sort_column
      columns.detect { |column|
        column.is_a?(BelongsToColumn) && column.name.to_s == sort
      }
    end
    
    def columns
      column_names = settings.column_names || model_class.columns.map(&:name)
      @admin_assistant.accumulate_columns column_names
    end
    
    def conditions
      settings.conditions
    end
    
    def find_include
      if by_assoc = belongs_to_sort_column
        by_assoc.name
      end
    end
    
    def model_class
      @admin_assistant.model_class
    end
    
    def order_sql
      if (sc = sort_column)
        first_part = if (by_assoc = belongs_to_sort_column)
          by_assoc.order_sql_field
        else
          sc.name
        end
        "#{first_part} #{sort_order}"
      else
        settings.sort_by
      end
    end
    
    def records
      unless @records
        ar_query = ARQuery.new(
          :order => order_sql, :include => find_include,
          :per_page => 25, :page => @url_params[:page]
        )
        search.add_to_query(ar_query)
        if conditions
          conditions_sql = conditions.call @url_params
          ar_query.condition_sqls << conditions_sql if conditions_sql
        end
        if settings.total_entries
          ar_query.total_entries = settings.total_entries.call
        end
        @records = model_class.paginate :all, ar_query.to_hash
      end
      @records
    end
    
    def right_column_links(record)
      settings.right_column_links.map { |link_lambda|
        link_lambda.call record
      }
    end
    
    def search
      @search ||= Search.new(@admin_assistant, @url_params['search'])
    end
    
    def search_terms
      @url_params['search']
    end
    
    def settings
      @admin_assistant.index_settings
    end
    
    def sort
      @url_params[:sort] ||
          (settings.sort_by.to_s if settings.sort_by.is_a?(Symbol))
    end
    
    def sort_column
      if sort
        columns.detect { |c|
          c.name.to_s == sort
        } || belongs_to_sort_column
      elsif settings.sort_by.is_a?(Symbol)
        columns.detect { |c| c.name == settings.sort_by.to_s }
      end
    end
    
    def sort_order
      @url_params[:sort_order] || 'asc'
    end
    
    def view(action_view)
      @view ||= View.new(
        self, action_view, @admin_assistant.custom_column_labels
      )
    end
    
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
            @admin_assistant.column(
              column_name.to_s,
              :search_terms => @search_params[column_name],
              :search_comparator =>
                  @search_params["#{column_name}(comparator)"]
            )
          }
          columns
        end
      end
      
      def column_views(action_view)
        columns.map { |c|
          opts = {
            :search => self,
            :label => @admin_assistant.custom_column_labels[c.name]
          }
          if c.respond_to?(:name) && c.name
            opts[:boolean_labels] =
                @admin_assistant.index_settings.boolean_labels[c.name]
            opts[:comparators] = settings.comparators[c.name.to_sym]
          end
          c.search_view(action_view, opts)
        }
      end
      
      def id
      end
      
      def method_missing(meth, *args)
        if column = columns.detect { |c| c.name == meth.to_s }
          column.search_value
        else
          super
        end
      end
    
      def settings
        @admin_assistant.search_settings
      end
    end
    
    class View
      def initialize(index, action_view, custom_column_labels)
        @index, @action_view, @custom_column_labels =
            index, action_view, custom_column_labels
      end
      
      def columns
        unless @columns
          @columns = @index.columns.map { |c|
            c.index_view(
              @action_view,
              :boolean_labels => @index.settings.boolean_labels[c.name],
              :sort_order => (@index.sort_order if c.name == @index.sort),
              :link_to_args => @index.settings.link_to_args[c.name.to_sym],
              :label => @custom_column_labels[c.name]
            )
          }
        end
        @columns
      end
    end
  end
end
