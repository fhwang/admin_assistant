class AdminAssistant
  class Column
    def blank?(search)
      search.params["#{name}(blank)"] == '1'
    end

    def comparator(search)
      search.params["#{name}(comparator)"]
    end
    
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
    
    def verify_for_search
      # nothing here, maybe implemented in subclasses
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
      
      def after_html(rails_form)
        after = render_from_custom_template("_after_#{name}_input", rails_form)
        if after
          after
        else
          helper_method = "after_#{name}_input"
          if @action_view.respond_to?(helper_method)
            @action_view.send(helper_method, rails_form.object)
          end
        end
      end
    
      def controller
        @action_view.controller
      end

      def html(rails_form)
        record = rails_form.object
        hff = render_from_custom_template "_#{name}_input", rails_form
        hff ||= html_from_helper_method(record)
        hff ||= if @read_only
          value record
        elsif @write_once && @action_view.action_name == 'edit'
          value record
        else
          default_html rails_form
        end
        if ah = after_html(rails_form)
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
      
      def render_from_custom_template(slug, rails_form)
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
          varname = @model_class.name.underscore
          @action_view.instance_variable_set(
            "@#{varname}".to_sym, rails_form.object
          )
          @action_view.render(
            :file => template,
            :locals => {
              varname.to_sym => rails_form.object,
              :form => rails_form
            }
          )
        end
      end
      
      def set_instance_variables_from_options(admin_assistant, opts)
        setting = admin_assistant.form_settings[name.to_sym]
        @clear_link = setting.clear_link
        @description = setting.description
        @datetime_select_options = setting.datetime_select_options || {}
        @date_select_options = setting.date_select_options || {}
        fum_name = name + '_url'
        if @action_view.respond_to?(fum_name)
          @file_url_method = @action_view.method(fum_name)
        end
        @image_size = setting.image_size
        @input = setting.input
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
      def header_css_class
        "sort #{sort_order}" if sort_order
      end
      
      def td_css_class
        'sort' if sort_order
      end
      
      def unconfigured_html(record)
        @action_view.send(:h, string(record))
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
        else
          unconfigured_html(record)
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
        setting = admin_assistant.search_settings[name.to_sym]
        unless setting.comparators == false
          @comparators = :all
        end
        @search = opts[:search]
        @blank_checkbox = setting.blank_checkbox
      end
    end
    
    module SimpleColumnSearchViewMethods
      include SearchViewMethods
      
      def boolean_input(form)
        opts = [['', nil]]
        if @boolean_labels
          opts << [@boolean_labels.first, true]
          opts << [@boolean_labels.last, false]
        else
          opts << ['true', true]
          opts << ['false', false]
        end
        form.select(name, opts)
      end
      
      def comparator_html(search)
        selected_comparator = @column.comparator(search) || '='
        option_tags = comparator_opts.map { |text, value|
          opt = "<option value=\"#{value}\""
          if selected_comparator == value
            opt << " selected=\"selected\""
          end
          opt << ">#{text}</option>"
        }.join("\n")
        @action_view.select_tag(
          "search[#{name}(comparator)]", option_tags
        )
      end
      
      def comparator_opts
        [
          ['greater than', '>'], ['greater than or equal to', '>='],
          ['equal to', '='], ['less than or equal to', '<='],
          ['less than', '<']
        ]
      end
      
      def html(form)
        input = ''
        case @column.field_type
          when :boolean
            input = boolean_input form
          else
            if @column.field_type == :integer && @comparators == :all
              input << comparator_html(form.object) << ' '
            end
            input << form.text_field(name)
            if @blank_checkbox
              input << check_box_and_hidden_tags(
                "search[#{name}(blank)]", @column.blank?(form.object)
              )
              input << "is blank"
            end
        end
        "<p><label>#{label}</label> <br/>#{input}</p>"
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
        fem_name = name + '_exists?'
        if @action_view.respond_to?(fem_name)
          @file_exists_method = @action_view.method(fem_name)
        end
        @label = base_setting.label
        @polymorphic_types = base_setting.polymorphic_types
        if respond_to?(:set_instance_variables_from_options)
          set_instance_variables_from_options(admin_assistant, opts)
        end
      end
      
      def check_box_and_hidden_tags(input_name, value)
        # Rails 2.3 wants the hidden tag to come before the checkbox, but it's
        # the opposite for Rails 2.2 and 2.1
        if RAILS_GEM_VERSION =~ /^2.3/
          @action_view.send(:hidden_field_tag, input_name, '0') +
              @action_view.send(:check_box_tag, input_name, '1', value)
        else
          @action_view.send(:check_box_tag, input_name, '1', value) +
              @action_view.send(:hidden_field_tag, input_name, '0')
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
      
      def sort_possible?(total_entries)
        @column.is_a?(ActiveRecordColumn) ||
            (@column.is_a?(BelongsToColumn) && total_entries < 100_000)
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
end
