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
        if conditions
          conditions_sql = conditions.call @url_params
          ar_query.condition_sqls << conditions_sql if conditions_sql
        end
        search.add_to_query(ar_query)
        if settings.total_entries
          ar_query.total_entries = settings.total_entries.call
        end
        @records = model_class.paginate :all, ar_query.to_hash
      end
      @records
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
        self, action_view, @admin_assistant
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
            @admin_assistant.column(
              column_name.to_s,
              :search_terms => @search_params[column_name],
              :search_comparator =>
                  @search_params["#{column_name}(comparator)"],
              :match_text_fields =>
                  settings[column_name.to_sym].
                  match_text_fields_for_association?
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
                @admin_assistant.index_settings[c.name].boolean_labels
            opts[:comparators] = settings[c.name.to_sym].comparators
          end
          c.search_view(action_view, opts)
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
      def initialize(index, action_view, admin_assistant)
        @index, @action_view = index, action_view
        @custom_column_labels = admin_assistant.custom_column_labels
        @ajax_toggle_allowed = admin_assistant.update?
        @right_column_show = admin_assistant.show?
        @right_column_update = admin_assistant.update?
        @right_column_destroy = admin_assistant.destroy?
        @right_column_lambdas =
            admin_assistant.index_settings.right_column_links
      end
      
      def columns
        unless @columns
          @columns = @index.columns.map { |c|
            c.index_view(
              @action_view,
              :boolean_labels => @index.settings[c.name].boolean_labels,
              :sort_order => (@index.sort_order if c.name == @index.sort),
              :link_to_args => @index.settings[c.name.to_sym].link_to_args,
              :label => @custom_column_labels[c.name],
              :image_size => @index.settings[c.name.to_sym].image_size,
              :ajax_toggle_allowed => @ajax_toggle_allowed
            )
          }
        end
        @columns
      end
      
      def right_column?
        @right_column_update or
            @right_column_destroy or
            @right_column_show or
            !@right_column_lambdas.empty?
      end
      
      def right_column_links(record)
        links = ""
        if @right_column_update
          links << @action_view.link_to(
            'Edit', :action => 'edit', :id => record.id
          ) << " "
        end
        if @right_column_destroy
          links << @action_view.link_to_remote(
            'Delete',
            :url => {:action => 'destroy', :id => record.id},
            :confirm => 'Are you sure?',
            :success => "Effect.Fade('record_#{record.id}')"
          ) << ' '
        end
        if @right_column_show
          links << @action_view.link_to(
            'Show', :action => 'show', :id => record.id
          ) << ' '
        end
        @right_column_lambdas.each do |lambda|
          link_args = lambda.call record
          links << @action_view.link_to(*link_args)
        end
        links
      end
    end
  end
end
