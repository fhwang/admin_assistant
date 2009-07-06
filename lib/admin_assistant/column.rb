class AdminAssistant
  class Column
    def form_view(action_view, admin_assistant, opts = {})
      view 'FormView', action_view, admin_assistant, opts
    end
    
    def index_view(action_view, admin_assistant, opts = {})
      view 'IndexView', action_view, admin_assistant, opts
    end
    
    def search_view(action_view, admin_assistant, opts = {})
      view 'SearchView', action_view, admin_assistant, opts
    end
    
    def show_view(action_view, admin_assistant, opts = {})
      view 'ShowView', action_view, admin_assistant, opts
    end
    
    def view(view_class_name, action_view, admin_assistant, opts)
      klass = begin
        self.class.const_get view_class_name
      rescue NameError
        AdminAssistant::Column.const_get view_class_name
      end
      klass.new self, action_view, admin_assistant, opts
    end
    
    module FormViewMethods
      def description
        @description
      end
      
      def after_html(record)
        if after = render_from_custom_template("_after_#{name}_input", record)
          after
        else
          helper_method = "after_#{name}_input"
          if @action_view.respond_to?(helper_method)
            @action_view.send(helper_method, record)
          end
        end
      end
    
      def controller
        @action_view.controller
      end

      def html(rails_form)
        record = rails_form.object
        hff = render_from_custom_template "_#{name}_input", record
        hff ||= html_from_helper_method(record)
        hff ||= if @read_only
          value record
        elsif @write_once && @action_view.action_name == 'edit'
          value record
        else
          default_html rails_form
        end
        if ah = after_html(record)
          hff << ah
        end
        hff
      end
    
      def html_from_helper_method(record)
        html_method = "#{name}_input"
        if @action_view.respond_to?(html_method)
          @action_view.send(html_method, record)
        end
      end
      
      def render_from_custom_template(slug, record)
        abs_template_file = File.join(
          RAILS_ROOT, 'app/views', controller.controller_path, 
          "#{slug}.html.erb"
        )
        if File.exist?(abs_template_file)
          template = if RAILS_GEM_VERSION == '2.1.0'
            File.join(controller.controller_path, "#{slug}.html.erb")
          else
            abs_template_file
          end
          @action_view.render(
            :file => template,
            :locals => {@model_class.name.underscore.to_sym => record}
          )
        end
      end
      
      def set_instance_variables_from_options(admin_assistant, opts)
        setting = admin_assistant.form_settings[name.to_sym]
        @input = setting.input
        @description = setting.description
        @datetime_select_options = setting.datetime_select_options || {}
        @date_select_options = setting.date_select_options || {}
        fem_name = name + '_exists?'
        if @action_view.controller.respond_to?(fem_name)
          @file_exists_method = @action_view.controller.method(fem_name)
        end
        fum_name = name + '_url'
        if @action_view.controller.respond_to?(fum_name)
          @file_url_method = @action_view.controller.method(fum_name)
        end
        @image_size = setting.image_size
        @nilify_link = setting.nilify_link
        @polymorphic_types = admin_assistant[name.to_sym].polymorphic_types
        @read_only = setting.read_only?
        @select_options = setting.select_options || {}
        unless @select_options.has_key?(:include_blank)
          @select_options[:include_blank] = true
        end
        @text_area_options = setting.text_area_options || {}
        @write_once = setting.write_once?
      end
    end
    
    module IndexViewMethods
      def ajax_toggle?
        false
      end

      def header_css_class
        "sort #{sort_order}" if sort_order
      end
      
      def td_css_class
        'sort' if sort_order
      end
      
      def html(record)
        html_for_index_method = "#{name}_html_for_index"
        html = if @action_view.respond_to?(html_for_index_method)
          @action_view.send html_for_index_method, record
        elsif @link_to_args
          @action_view.link_to(
            @action_view.send(:h, string(record)),
            @link_to_args.call(record)
          )
        elsif ajax_toggle?
          ajax_toggle_html(record)
        else
          @action_view.send(:h, string(record))
        end
        html = '&nbsp;' if html.blank?
        html
      end
    
      def next_sort_params
        name_for_sort = name
        next_sort_order = 'asc'
        if sort_order
          if sort_order == 'asc'
            next_sort_order = 'desc'
          else
            name_for_sort = nil
            next_sort_order = nil
          end
        end
        @action_view.params.merge(
          :sort => name_for_sort, :sort_order => next_sort_order
        )
      end
      
      def set_instance_variables_from_options(admin_assistant, opts)
        index = opts[:index]
        setting = admin_assistant.index_settings[name.to_sym]
        @link_to_args = setting.link_to_args
        @sort_order = index.sort_order if name == index.sort
        @image_size = setting.image_size
        @ajax_toggle_allowed = admin_assistant.update?
      end
    end
    
    module SearchViewMethods      
      def set_instance_variables_from_options(admin_assistant, opts)
        @search = opts[:search]
      end
    end
    
    module ShowViewMethods
      def html(record)
        @action_view.send(:h, value(record))
      end
    end

    class View
      attr_reader :sort_order
      
      def initialize(column, action_view, admin_assistant, opts = {})
        @column, @action_view, @opts = column, action_view, opts
        @model_class = admin_assistant.model_class
        base_setting = admin_assistant[name]
        @boolean_labels = base_setting.boolean_labels
        @label = base_setting.label
        @polymorphic_types = base_setting.polymorphic_types
        if respond_to?(:set_instance_variables_from_options)
          set_instance_variables_from_options(admin_assistant, opts)
        end
      end
      
      def label
        if @label
          @label
        elsif @column.name.to_s == 'id'
          'ID'
        else
          @column.name.to_s.capitalize.gsub(/_/, ' ') 
        end
      end
      
      def name
        @column.name
      end
      
      def paperclip?
        @column.is_a?(PaperclipColumn)
      end
      
      def sort_possible?
        @column.is_a?(ActiveRecordColumn) || @column.is_a?(BelongsToColumn)
      end
      
      def string(record)
        string_method = "#{@column.name}_string"
        if @action_view.respond_to?(string_method)
          @action_view.send string_method, record
        else
          value = value(record)
          if @boolean_labels
            value ? @boolean_labels.first : @boolean_labels.last
          else
            value.to_s
          end
        end
      end
      
      def value(record)
        record.send(name) if record.respond_to?(name)
      end
    end
    
    class FormView < View
      include IndexViewMethods
    end

    class IndexView < View
      include IndexViewMethods
    end
    
    class SearchView < View
      include SearchViewMethods
    end
    
    class ShowView < View
      include ShowViewMethods
    end
  end
  
  class AssociationTarget
    def initialize(associated_class)
      @associated_class = associated_class
    end
    
    def assoc_value(assoc_value)
      if assoc_value.respond_to?(:name_for_admin_assistant)
        assoc_value.name_for_admin_assistant
      elsif assoc_value && default_name_method
        assoc_value.send default_name_method
      end
    end
      
    def default_name_method
      [:name, :title, :login, :username].detect { |m|
        @associated_class.columns.any? { |column| column.name.to_s == m.to_s }
      }
    end
    
    def name
      @associated_class.name.gsub(/([A-Z])/, ' \1')[1..-1].downcase
    end
      
    def options_for_select
      @associated_class.
          find(:all).
          sort_by { |model| model.send(default_name_method) }.
          map { |model| [model.send(default_name_method), model.id] }
    end
  end
end
