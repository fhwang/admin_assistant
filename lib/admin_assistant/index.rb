require 'ar_query'

class AdminAssistant
  class Index
    attr_reader :admin_assistant, :controller_methods, :url_params
    
    def initialize(admin_assistant, url_params = {}, controller_methods = {})
      @admin_assistant, @url_params, @controller_methods =
            admin_assistant, url_params, controller_methods
    end
    
    def belongs_to_columns
      @admin_assistant.accumulate_belongs_to_columns column_names
    end
    
    def column_names
      settings.column_names || model_class.columns.map(&:name)
    end
    
    def columns
      @admin_assistant.accumulate_columns column_names
    end
    
    def model_class
      @admin_assistant.model_class
    end
    
    def records
      @records ||= RecordFinder.new(self).run
    end
    
    def search
      @search ||= AdminAssistant::Search.new(
        @admin_assistant, @url_params['search']
      )
    end
    
    def search_requested?
      !@url_params['search'].blank?
    end
    
    def settings
      @admin_assistant.index_settings
    end
    
    def sort
      @url_params[:sort] ||
          (settings.sort_by.to_s if settings.sort_by.is_a?(Symbol))
    end
    
    def sort_order
      @url_params[:sort_order] || 'asc'
    end
    
    def view(action_view)
      @view ||= View.new(self, action_view, @admin_assistant)
    end
      
    class RecordFinder
      def initialize(index)
        @index = index
      end
      
      def add_base_condition_sqls
        if @index.controller_methods[:conditions_for_index]
          sql = @index.controller_methods[:conditions_for_index].call
          @ar_query.condition_sqls << sql if sql
        elsif conditions_from_settings
          if conditions_from_settings.respond_to?(:call)
            conditions_sql = conditions_from_settings.call @index.url_params
          else
            conditions_sql = conditions_from_settings
          end
          @ar_query.condition_sqls << conditions_sql if conditions_sql
        end
      end
      
      def belongs_to_sort_column
        @index.belongs_to_columns.detect { |c| c.name.to_s == @index.sort }
      end
    
      def conditions_from_settings
        settings.conditions
      end
    
      def find_include
        fi = settings.include || []
        if by_assoc = belongs_to_sort_column
          fi << by_assoc.name
        end
        fi
      end
    
      def order_sql
        if (sc = sort_column)
          first_part = if (by_assoc = belongs_to_sort_column)
            by_assoc.order_sql_field
          else
            sc.name
          end
          "#{first_part} #{@index.sort_order}"
        else
          settings.sort_by
        end
      end
      
      def run
        @ar_query = ARQuery.new(
          :order => order_sql, :include => find_include,
          :per_page => settings.per_page, :page => @index.url_params[:page]
        )
        add_base_condition_sqls
        search.add_to_query @ar_query
        if settings.total_entries
          @ar_query.total_entries = settings.total_entries.call
        elsif search.params.empty? &&
              (time_span = settings.cache_total_entries)
          @ar_query.total_entries = Rails.cache.read total_entries_cache_key
        end
        records = @index.model_class.paginate(:all, @ar_query.to_hash)
        if search.params.empty? &&
           (time_span = settings.cache_total_entries) &&
           @ar_query.to_hash[:total_entries].nil?
          Rails.cache.write(
            total_entries_cache_key, records.total_entries,
            :expires_in => time_span
          )
        end
        records
      end
      
      def search
        @index.search
      end
      
      def settings
        @index.settings
      end
    
      def sort_column
        if @index.sort
          @index.columns.detect { |c|
            c.name.to_s == @index.sort
          } || belongs_to_sort_column
        elsif settings.sort_by.is_a?(Symbol)
          @index.columns.detect { |c| c.name == settings.sort_by.to_s }
        end
      end
    
      def total_entries_cache_key
        key =
            "AdminAssistant::#{@index.admin_assistant.controller_class.name}_count"
        if conditions = @ar_query.to_hash[:conditions]
          key << conditions.gsub(/\W/, '_')
        end
        key
      end
    end
    
    class View
      def initialize(index, action_view, admin_assistant)
        @index, @action_view, @admin_assistant =
            index, action_view, admin_assistant
      end
      
      def render_filter
        slug = "_filter.html.erb"
        abs_template_file = File.join( Rails.root, 'app/views', @admin_assistant.controller_class.controller_path, slug )
        if File.exist?(abs_template_file)
          template = if RAILS_GEM_VERSION == '2.1.0'
            File.join(@admin_assistant.controller_class.controller_path, slug)
          else
            abs_template_file
          end
          @action_view.render :file => template
        end
      end
      
      def ajax_toggle_allowed?
        @admin_assistant.update?
      end
      
      def columns
        unless @columns
          @columns = @index.columns.map { |c|
            c.index_view @action_view, @admin_assistant, :index => @index
          }
        end
        @columns
      end
      
      def delete_link(record)
        @action_view.link_to_remote(
          'Delete',
          :url => {:action => 'destroy', :id => record.id},
          :confirm => 'Are you sure?',
          :success =>
              "Effect.Fade('#{@admin_assistant.model_class.name.underscore}_#{record.id}')",
          :method => :delete
        ) << ' '
      end
      
      def destroy?
        @destroy ||= @admin_assistant.destroy?
      end
      
      def edit?
        @edit ||= @admin_assistant.edit?
      end
      
      def edit_link(record)
        @action_view.link_to(
          'Edit', :action => 'edit', :id => record.id
        ) << " "
      end
      
      def new?
        @new ||= @admin_assistant.new?
      end
      
      def header
        if block = @index.settings.header
          block.call @action_view.params
        else
          @admin_assistant.model_class_name.pluralize.capitalize
        end
      end

      def right_column?
        edit? or destroy? or show? or !right_column_lambdas.empty?
      end
      
      def right_column_lambdas
        @right_column_lambdas ||=
            @admin_assistant.index_settings.right_column_links
      end
      
      def right_column_links(record)
        links = ""
        links << edit_link(record) if render_edit_link?(record)
        links << delete_link(record) if render_delete_link?(record)
        if render_show_link?(record)
          links << @action_view.link_to(
            'Show', :action => 'show', :id => record.id
          ) << ' '
        end
        right_column_lambdas.each do |lambda|
          link_args = lambda.call record
          links << @action_view.link_to(*link_args)
        end
        if @action_view.respond_to?(:extra_right_column_links_for_index)
          links << @action_view.extra_right_column_links_for_index(
            record
          ) || ''
        end
        links
      end
      
      def render_new_link?
        return false if @action_view.respond_to?(:link_to_new_in_index?) && !@action_view.link_to_new_in_index?
        new?
      end
      
      def render_edit_link?(record)
        return false if @action_view.respond_to?(:link_to_edit_in_index?) && !@action_view.link_to_edit_in_index?(record)
        edit?
      end
      
      def render_delete_link?(record)
        return false if @action_view.respond_to?(:link_to_delete_in_index?) && !@action_view.link_to_delete_in_index?(record)
        destroy?
      end
      
      def render_show_link?(record)
        return false if @action_view.respond_to?(:link_to_show_in_index?) && !@action_view.link_to_show_in_index?(record)
        show?
      end
      
      def show?
        @show ||= @admin_assistant.show?
      end
    end
  end
end
