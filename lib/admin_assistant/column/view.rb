class AdminAssistant
  class Column
    class View < Delegator
      attr_reader :sort_order
      
      def initialize(column, action_view, opts = {})
        super(column)
        @column, @action_view, @opts = column, action_view, opts
        @boolean_labels = opts[:boolean_labels]
        @label = opts[:label]
        if respond_to?(:set_instance_variables_from_options)
          set_instance_variables_from_options(opts)
        end
      end
      
      def __getobj__
        @column
      end
      
      def __setobj__(column)
        @column = column
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
      
      def paperclip?
        @column.is_a?(PaperclipColumn)
      end
      
      def sort_possible?
        @column.is_a?(ActiveRecordColumn) || @column.is_a?(BelongsToColumn)
      end
    end
    
    module FormViewMethods
      def description
        @description
      end
      
      def value(record)
        value_method = "#{@column.name}_value"
        if @action_view.respond_to?(value_method)
          @action_view.send value_method, record
        else
          field_value record
        end
      end
      
      def set_instance_variables_from_options(opts)
        @input = opts[:input]
        @description = opts[:description]
        @datetime_select_options = opts[:datetime_select_options] || {}
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
            @action_view.send(:h, value(record)),
            @link_to_args.call(record)
          )
        elsif ajax_toggle?
          ajax_toggle_html(record)
        else
          @action_view.send(:h, value(record))
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
      
      def value(record)
        value_method = "#{@column.name}_value"
        if @action_view.respond_to?(value_method)
          @action_view.send value_method, record
        else
          field_value record
        end
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
        @action_view.send(:h, field_value(record))
      end
    end
  end
  
  class ActiveRecordColumn < Column
    class View < AdminAssistant::Column::View
      def field_value(record)
        record.send(name) if record.respond_to?(name)
      end
    end
    
    class FormView < View
      include AdminAssistant::Column::FormViewMethods
      
      def html(form)
        case @input || @column.sql_type
          when :text
            form.text_area name
          when :boolean
            form.check_box name
          when :datetime
            form.datetime_select(
              name, {:include_blank => true}.merge(@datetime_select_options)
            )
          when :date
            form.date_select name, :include_blank => true
          when :us_state
            form.select(
              name, ordered_us_state_names_and_codes, :include_blank => true
            )
          else
            form.text_field name
          end
      end
      
      def ordered_us_state_names_and_codes
        {
          'Alabama' => 'AL', 'Alaska' => 'AK', 'Arizona' => 'AZ',
          'Arkansas' => 'AR', 'California' => 'CA', 'Colorado' => 'CO', 
          'Connecticut' => 'CT', 'Delaware' => 'DE',
          'District of Columbia' => 'DC', 'Florida' => 'FL', 'Georgia' => 'GA',
          'Hawaii' => 'HI', 'Idaho' => 'ID', 'Illinois' => 'IL',
          'Indiana' => 'IN', 'Iowa' => 'IA', 'Kansas' => 'KS',
          'Kentucky' => 'KY', 'Louisiana' => 'LA', 'Maine' => 'ME',
          'Maryland' => 'MD', 'Massachusetts' => 'MA', 'Michigan' => 'MI', 
          'Minnesota' => 'MN', 'Mississippi' => 'MS', 'Missouri' => 'MO', 
          'Montana' => 'MT', 'Nebraska' => 'NE', 'Nevada' => 'NV',
          'New Hampshire' => 'NH', 'New Jersey' => 'NJ', 'New Mexico' => 'NM', 
          'New York' => 'NY', 'North Carolina' => 'NC', 'North Dakota' => 'ND',
          'Ohio' => 'OH', 'Oklahoma' => 'OK', 'Oregon' => 'OR',
          'Pennsylvania' => 'PA', 'Puerto Rico' => 'PR',
          'Rhode Island' => 'RI', 'South Carolina' => 'SC',
          'South Dakota' => 'SD', 'Tennessee' => 'TN', 'Texas' => 'TX',
          'Utah' => 'UT', 'Vermont' => 'VT', 'Virginia' => 'VA',
          'Washington' => 'WA', 'West Virginia' => 'WV', 'Wisconsin' => 'WI', 
          'Wyoming' => 'WY'
        }.sort_by { |name, code| name }
      end
    end
    
    class IndexView < View
      include AdminAssistant::Column::IndexViewMethods

      def ajax_toggle?
        @column.sql_type == :boolean && @ajax_toggle_allowed
      end
      
      def ajax_toggle_div_id(record)
        "#{record.class.name.underscore}_#{record.id}_#{name}"
      end
      
      def ajax_toggle_html(record)
        <<-HTML
        <div id="#{ ajax_toggle_div_id(record) }">
        #{ajax_toggle_inner_html(record)}
        </div>
        HTML
      end
      
      def ajax_toggle_inner_html(record)
        div_id = ajax_toggle_div_id record
        @action_view.link_to_remote(
          value(record),
          :update => div_id,
          :url => {
            :action => 'update', :id => record.id, :from => div_id,
            record.class.name.underscore.to_sym => {
              name => (!value(record) ? '1' : '0')
            }
          },
          :success => "$(#{div_id}).hide(); $(#{div_id}).appear()"
        )
      end

      def value(record)
        value = super
        if @boolean_labels
          value = value ? @boolean_labels.first : @boolean_labels.last
        end
        value
      end
    end
    
    class SearchView < View
      include AdminAssistant::Column::SearchViewMethods
      
      def comparator_html
        comparator_opts = [
          ['greater than', '>'], ['greater than or equal to', '>='],
          ['equal to', '='], ['less than or equal to', '<='],
          ['less than', '<']
        ]
        selected_comparator = @column.search_comparator || '='
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
      
      def html
        input = ''
        case @column.sql_type
          when :boolean
            opts = [['', nil]]
            if @boolean_labels
              opts << [@boolean_labels.first, true]
              opts << [@boolean_labels.last, false]
            else
              opts << ['true', true]
              opts << ['false', false]
            end
            input = @action_view.select("search", name, opts)
          else
            if @column.sql_type == :integer
              input << comparator_html << ' '
            end
            input << @action_view.text_field_tag(
              "search[#{name}]", @search[name]
            )
        end
        "<p><label>#{label}</label> <br/>#{input}</p>"
      end
    end
    
    class ShowView < View
      include AdminAssistant::Column::ShowViewMethods
    end
  end

  class AdminAssistantColumn < Column
    class View < AdminAssistant::Column::View
      def field_value(record)
        record.send(name) if record.respond_to?(name)
      end
    end
    
    class FormView < View
      include AdminAssistant::Column::FormViewMethods
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
  
  class BelongsToColumn < Column
    class View < AdminAssistant::Column::View
      def assoc_field_value(assoc_value)
        if assoc_value.respond_to?(:name_for_admin_assistant)
          assoc_value.name_for_admin_assistant
        elsif assoc_value && default_name_method
          assoc_value.send default_name_method
        end
      end
      
      def field_value(record)
        assoc_field_value record.send(name)
      end
      
      def options_for_select
        associated_class.
            find(:all).
            sort_by { |model| model.send(default_name_method) }.
            map { |model| [model.send(default_name_method), model.id] }
      end
    end
    
    class FormView < View
      include AdminAssistant::Column::FormViewMethods
      
      def html(form)
        if associated_class.count > 15
          @action_view.send(
            :render,
            :file => AdminAssistant.template_file('_restricted_autocompleter'),
            :use_full_path => false,
            :locals => {
              :record => form.object, :column => @column,
              :associated_class_name => associated_class.name.underscore,
              :select_options => @select_options
            }
          )
        else
          form.select(
            association_foreign_key, options_for_select, @select_options
          )
        end
      end
    end

    class IndexView < View
      include AdminAssistant::Column::IndexViewMethods
    end
    
    class SearchView < View
      include AdminAssistant::Column::SearchViewMethods
      
      def html
        input = if @column.match_text_fields
          @action_view.text_field_tag(
            "search[#{name}]", @column.search_terms
          )
        else
          @action_view.select(
            'search', name, options_for_select, :include_blank => true
          )
        end
        "<p><label>#{label}</label> <br/>#{input}</p>"
      end
    end
    
    class ShowView < View
      include AdminAssistant::Column::ShowViewMethods
    end
  end
  
  class DefaultSearchColumn < Column
    class View < AdminAssistant::Column::View
    end
    
    class FormView < View
      include AdminAssistant::Column::FormViewMethods
    end

    class IndexView < View
      include AdminAssistant::Column::IndexViewMethods
    end
    
    class SearchView < View
      include AdminAssistant::Column::SearchViewMethods
      
      def html
        @action_view.text_field_tag("search", @column.search_terms)
      end
    end
    
    class ShowView < View
      include AdminAssistant::Column::ShowViewMethods
    end
  end
  
  class FileColumnColumn < Column
    class View < AdminAssistant::Column::View
      def file_exists?(record)
        !source_for_image_tag(record).nil?
      end
      
      def image_html(record)
        @action_view.image_tag(
          source_for_image_tag(record), :size => @image_size
        )
      end
      
      def source_for_image_tag(record)
        @action_view.instance_variable_set :@record, record
        @action_view.url_for_file_column 'record', @column.name
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
end
