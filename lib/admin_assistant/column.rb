class AdminAssistant
  class Column    
    def sort_possible?(total_entries) false end

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
      def after_html(rails_form)
        after = render_from_custom_template("_after_#{name}_input", rails_form)
        if after
          after
        else
          helper_method = "after_#{name}_input"
          if @action_view.respond_to?(helper_method)
            @action_view.raw(
              @action_view.send(helper_method, rails_form.object)
            )
          end
        end
      end
      
      def description
        @description
      end
      
      def errors(record)
        record.errors[name]
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
      
      def field_id
        "#{@model_class.name.underscore}_#{name}"
      end
      
      def render_from_custom_template(slug, rails_form)
        if File.exist?(custom_template_file_path(slug))
          varname = @model_class.name.underscore
          @action_view.instance_variable_set(
            "@#{varname}".to_sym, rails_form.object
          )
          locals = {varname.to_sym => rails_form.object, :form => rails_form}
          if rails_form.respond_to?(:prefix)
            locals[:prefix] = rails_form.prefix
            @action_view.instance_variable_set(:@prefix, rails_form.prefix)
          end
          @action_view.render(
            :file => file_option_for_custom_template_render(slug),
            :locals => locals
          )
        end
      end
      
      def set_instance_variables_from_options(admin_assistant, opts)
        setting = admin_assistant.form_settings[name.to_sym]
        ivars = %w(
          clear_link datetime_select_options date_select_options description
          image_size input select_choices select_options text_area_options
        )
        ivars.each do |ivar|
          instance_variable_set "@#{ivar}".to_sym, setting.send(ivar)
        end
        if @action_view.respond_to?(name + '_url')
          @file_url_method = @action_view.method(name + '_url')
        end
        @read_only = setting.read_only?
        @write_once = setting.write_once?
      end
    end
    
    module IndexViewMethods
      def header_css_class
        "sort #{sort_order}" if sort_order
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
        @ajax_toggle_allowed =
            admin_assistant.update? && setting.ajax_toggle != false
      end
      
      def td_css_classes(column, record)
        css_classes = []
        css_classes << 'sort' if sort_order
        td_css_class_for_index_method = "#{name}_css_class_for_index_td"
        if @action_view.respond_to?(td_css_class_for_index_method)
          css_classes << @action_view.send(td_css_class_for_index_method, record)
        end
        css_classes.reject{ |c| c.blank? }.join(' ')
      end
      
      def unconfigured_html(record)
        @action_view.send(:h, string(record))
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
        @compare_to_range = setting.compare_to_range
      end
    end
    
    module SimpleColumnSearchViewMethods
      include SearchViewMethods
      
      def blank_checkbox_html(form)
        check_box_and_hidden_tags(
          "search[#{name}(blank)]", form.object.blank?(@column.name)
        ) + "is blank"
      end
      
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
        selected_comparator = search.comparator(@column.name) || '='
        option_tags = comparator_opts.map { |text, value|
          opt = "<option value=\"#{value}\""
          if selected_comparator == value
            opt << " selected=\"selected\""
          end
          opt << ">#{text}</option>"
        }.join("\n")
        @action_view.select_tag(
          "search[#{name}(comparator)]", @action_view.raw(option_tags)
        )
      end
      
      def comparator_opts
        [
          ['greater than', '>'], ['greater than or equal to', '>='],
          ['equal to', '='], ['less than or equal to', '<='],
          ['less than', '<']
        ]
      end
      
      def datetime_input(form)
        input = ''
        if @compare_to_range
          input = datetime_range_input(form)
        else
          input << comparator_html(form.object) << ' ' if @comparators == :all
          input << form.datetime_select(name, :include_blank => true)
          input << @action_view.send(
            :link_to, 'Clear', '#',
            'data-prefix' => "search_#{name.underscore}",
            :class => 'clear_datetime_select'
          )
        end
        input
      end
      
      def datetime_range_end_point_input(form, comparator, label)
        input = "#{label} "
        input << ActionView::Helpers::DateTimeSelector.new(
          form.object.send(name)[comparator], 
          :prefix => "search", :field_name => comparator.to_s,
          :include_position => true, :index => name, :include_blank => true,
          :datetime_separator => ' &mdash; ', :time_separator => ' : '
        ).select_datetime
        input << @action_view.send(
          :link_to, 'Clear', '#',
          'data-prefix' => "search_#{name.underscore}_#{comparator}",
          :class => 'clear_datetime_select'
        )
        input
      end
      
      def datetime_range_input(form)
        input = ''
        input << datetime_range_end_point_input(form, :gt, 'After')
        input << "&nbsp;&nbsp;&nbsp;"
        input << datetime_range_end_point_input(form, :lt, 'Before')
        input
      end
      
      def html(form)
        input = ''
        if @column.field_type == :boolean
          input = boolean_input form
        elsif @column.field_type == :datetime
          input = datetime_input form
        else
          if @compare_to_range
            input << "Greater than "
            input << @action_view.send(
              :text_field_tag, "search[#{name}][gt]",
              form.object.send(name)[:gt]
            )
            input << "&nbsp;&nbsp;&nbsp;Less than "
            input << @action_view.send(
              :text_field_tag, "search[#{name}][lt]",
              form.object.send(name)[:lt]
            )
          else
            if @column.field_type == :integer && @comparators == :all
              input << comparator_html(form.object) << ' '
            end
            input << form.text_field(name)
            input << blank_checkbox_html(form) if @blank_checkbox
          end
        end
        "<p><label>#{label}</label> <br/>#{input}</p>"
      end
    end
    
    module ShowViewMethods
      def html(record)
        slug = "_#{name}_for_show"
        if File.exist?(custom_template_file_path(slug))
          varname = @model_class.name.underscore
          @action_view.instance_variable_set("@#{varname}".to_sym, record)
          locals = {varname.to_sym => record}
          @action_view.render(
            :file => file_option_for_custom_template_render(slug),
            :locals => locals
          )
        else
          @action_view.send(:h, string(record))
        end
      end
    end

    class View
      attr_reader :sort_order
      
      def initialize(column, action_view, admin_assistant, opts = {})
        @column, @action_view, @opts = column, action_view, opts
        @model_class = admin_assistant.model_class
        base_setting = admin_assistant[name]
        @boolean_labels = base_setting.boolean_labels
        @strftime_format = base_setting.strftime_format
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
        @action_view.send(:hidden_field_tag, input_name, '0', :id => "#{input_name}_hidden") +
            @action_view.send(:check_box_tag, input_name, '1', value)
      end
    
      def controller
        @action_view.controller
      end
      
      def custom_template_file_path(slug)
        File.join(
          Rails.root, 'app/views', controller.controller_path, 
          "#{slug}.html.erb"
        )
      end
      
      def file_option_for_custom_template_render(slug)
        custom_template_file_path slug
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
      
      def sort_possible?(records, admin_assistant)
        total_entries = records.size
        return false if records.empty?
        model_class = model.first.class
        if admin_assistant.search_settings.column_names.include? @column.name.to_sym
          true
        else
          @column.sort_possible? model_class, total_entries
        end
      end
      
      def string(record)
        string_method = "#{@column.name}_string"
        if @action_view.respond_to?(string_method)
          @action_view.send string_method, record
        else
          value = value(record)
          if @boolean_labels
            value ? @boolean_labels.first : @boolean_labels.last
          elsif value.respond_to?(:strftime) && @strftime_format
            value.strftime @strftime_format
          else
            value.to_s
          end
        end
      end
      
      def value(record)
        value_method = "#{name}_value"
        if @action_view.respond_to?(value_method)
          @action_view.send value_method, record
        else
          record.send(name) if record.respond_to?(name)
        end
      end
    end
    
    class FormView < View
      include FormViewMethods
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
