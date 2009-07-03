class AdminAssistant
  class Column
    class View
      attr_reader :sort_order
      
      def initialize(column, action_view, opts = {})
        @column, @action_view, @opts = column, action_view, opts
        @boolean_labels = opts[:boolean_labels]
        @label = opts[:label]
        @polymorphic_types = opts[:polymorphic_types]
        if respond_to?(:set_instance_variables_from_options)
          set_instance_variables_from_options(opts)
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
          value(record).to_s
        end
      end
    end
    
    module FormViewMethods
      def description
        @description
      end
      
      def set_instance_variables_from_options(opts)
        @input = opts[:input]
        @description = opts[:description]
        @datetime_select_options = opts[:datetime_select_options] || {}
        @date_select_options = opts[:date_select_options] || {}
        @file_exists_method = opts[:file_exists_method]
        @file_url_method = opts[:file_url_method]
        @polymorphic_types = opts[:polymorphic_types]
        @select_options = opts[:select_options] || {}
        unless @select_options.has_key?(:include_blank)
          @select_options[:include_blank] = true
        end
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
      
      def set_instance_variables_from_options(opts)
        @link_to_args = opts[:link_to_args]
        @sort_order = opts[:sort_order]
        @image_size = opts[:image_size]
        @ajax_toggle_allowed = opts[:ajax_toggle_allowed]
      end
    end
    
    module SearchViewMethods      
      def set_instance_variables_from_options(opts)
        @search = opts[:search]
      end
    end
    
    module ShowViewMethods
      def html(record)
        @action_view.send(:h, value(record))
      end
    end
  end
  
  class FileColumnColumn < Column
    class View < AdminAssistant::Column::View
      def file_exists?(record)
        if @file_exists_method
          @file_exists_method.call record
        else
          !source_for_image_tag(record).nil?
        end
      end
      
      def image_html(record)
        @action_view.image_tag(
          source_for_image_tag(record), :size => @image_size
        )
      end
      
      def source_for_image_tag(record)
        if @file_url_method
          @file_url_method.call record
        else
          @action_view.instance_variable_set :@record, record
          @action_view.url_for_file_column 'record', @column.name
        end
      end
    end
    
    class FormView < View
      include AdminAssistant::Column::FormViewMethods
      
      def html(form)
        if file_exists?(form.object)
          check_box_tag = @action_view.check_box_tag(
            "#{form.object.class.name.underscore}[#{name}(destroy)]"
          )
          <<-HTML
          <p>Current image:<br />#{image_html(form.object)}</p>
          <p>Remove: #{check_box_tag}</p>
          <p>Update: #{form.file_field(name)}</p>
          HTML
        else
          "<p>Add: #{form.file_field(name)}</p>"
        end
      end
    end

    class IndexView < View
      include AdminAssistant::Column::IndexViewMethods
      
      def html(record)
        image_html(record) if file_exists?(record)
      end
    end
    
    class SearchView < View
      include AdminAssistant::Column::SearchViewMethods
    end
    
    class ShowView < View
      include AdminAssistant::Column::ShowViewMethods
      
      def html(record)
        image_html(record) if file_exists?(record)
      end
    end
  end
  
  class PaperclipColumn < Column
    class View < AdminAssistant::Column::View
      def image_html(record)
        @action_view.image_tag record.send(@column.name).url
      end
    end
    
    class FormView < View
      include AdminAssistant::Column::FormViewMethods
      
      def html(form)
        form.file_field name
      end
    end

    class IndexView < View
      include AdminAssistant::Column::IndexViewMethods
      
      def html(record)
        image_html record
      end
    end
    
    class SearchView < View
      include AdminAssistant::Column::SearchViewMethods
    end
    
    class ShowView < View
      include AdminAssistant::Column::ShowViewMethods
      
      def html(record)
        image_html record
      end
    end
  end
  
  class PolymorphicBelongsToColumn < Column
    class View < AdminAssistant::Column::View
      def assoc_value(assoc_value)
        if assoc_value.respond_to?(:name_for_admin_assistant)
          assoc_value.name_for_admin_assistant
        elsif assoc_value
          association_target = AssociationTarget.new assoc_value.class
          if dnm = association_target.default_name_method
            assoc_value.send dnm
          end
        end
      end
      
      def value(record)
        record.send name
      end
    end
    
    class FormView < View
      include AdminAssistant::Column::FormViewMethods
      
      def html(form)
        opts_for_select = @polymorphic_types.map { |t| [t.name, t.name] }
        form.select(name + '_type', opts_for_select, @select_options) + " " +
            form.text_field(name + '_id', :class => 'integer')
      end
    end

    class IndexView < View
      include AdminAssistant::Column::IndexViewMethods
      
      def value(record)
        target = record.send name
        if target
          str = AssociationTarget.new(target.class).name.capitalize
          fv = assoc_value target
          if fv
            str << " '#{fv}'"
          else
            str << " #{target.id}"
          end
        end
      end
    end
    
    class SearchView < View
      include AdminAssistant::Column::SearchViewMethods
      
      def html(form)
        @action_view.send(
          :render,
          :file => AdminAssistant.template_file('_polymorphic_field_search'),
          :use_full_path => false,
          :locals => {
            :record => @search, :column => @column,
            :polymorphic_types => @polymorphic_types
          }
        )
      end
    end
    
    class ShowView < View
      include AdminAssistant::Column::ShowViewMethods
    end
  end

  class VirtualColumn < Column
    class View < AdminAssistant::Column::View
      def value(record)
        record.send(name) if record.respond_to?(name)
      end
    end
    
    class FormView < View
      include AdminAssistant::Column::FormViewMethods
      
      def html(form)
        input_name = "#{@column.model_class.name.underscore}[#{name}]"
        if @input
          if @input == :check_box
            fv = value form.object
            # Rails 2.3 wants the hidden tag to come before the checkbox, but
            # it's the opposite for Rails 2.2 and 2.1
            if RAILS_GEM_VERSION =~ /^2.3/
              @action_view.send(:hidden_field_tag, input_name, '0') +
                  @action_view.send(:check_box_tag, input_name, '1', fv)
            else
              @action_view.send(:check_box_tag, input_name, '1', fv) +
                  @action_view.send(:hidden_field_tag, input_name, '0')
            end
          end
        else
          @action_view.send(:text_field_tag, input_name, string(form.object))
        end
      end
    end

    class IndexView < View
      include AdminAssistant::Column::IndexViewMethods
    end
    
    class SearchView < View
      include AdminAssistant::Column::SearchViewMethods
    end
    
    class ShowView < View
      include AdminAssistant::Column::ShowViewMethods
    end
  end
end
