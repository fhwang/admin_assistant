class AdminAssistant
  class ActiveRecordColumn < Column
    def initialize(ar_column)
      @ar_column = ar_column
    end
    
    def add_to_query_condition(ar_query_condition, search)
      ConditionUpdate.new(ar_query_condition, search, name, field_type).run
    end
      
    def attributes_for_search_object(search_params, compare_to_range)
      attrs = {}
      if compare_to_range
        attrs[name] = range_attribute_for_search_object search_params[name]
      else
        attrs[name] = if field_type == :datetime
          datetime_attributes_for_search_object search_params, name
        else
          terms = search_params[@ar_column.name]
          unless terms.blank?
            case field_type
              when :boolean
                terms.blank? ? nil : (terms == 'true')
              else
                terms
            end
          end
        end
      end
      attrs
    end
    
    def contains?(column_name)
      column_name.to_s == @ar_column.name
    end
    
    def datetime_attributes_for_search_object(search_params, prefix)
      begin
        Time.utc(
          *(1..5).to_a.map { |i| search_params["#{prefix}(#{i}i)"].to_i }
        )
      rescue ArgumentError; end
    end
    
    def field_type
      @ar_column.type
    end
    
    def name
      @ar_column.name
    end
    
    def range_attribute_for_search_object(column_params)
      range = {}
      if column_params
        %w(gt lt).each do |comparator|
          if column_params.keys.any? { |k| k.to_s =~ /^#{comparator}/ }
            range[comparator.to_sym] = if field_type == :datetime
              datetime_attributes_for_search_object(column_params, comparator)
            else
              column_params[comparator] unless column_params[comparator].blank?
            end
          end
        end
      end
      range
    end
      
    class ConditionUpdate
      def initialize(ar_query_condition, search, name, field_type)
        @ar_query_condition, @search, @name, @field_type =
            ar_query_condition, search, name, field_type
      end
      
      def add_blank_condition
        @ar_query_condition.add_condition do |sub_cond|
          sub_cond.boolean_join = :or
          sub_cond.sqls << "#{table_name}.#{@name} is null"
          sub_cond.sqls << "#{table_name}.#{@name} = ''"
        end
      end
      
      def add_case_insensitive_string_comparison
        @ar_query_condition.sqls <<
            "LOWER(#{table_name}.#{@name}) like LOWER(?)"
        @ar_query_condition.bind_vars << "%#{value_for_query}%"
      end
      
      def add_comparative_condition
        @ar_query_condition.sqls << "#{table_name}.#{@name} #{comparator} ?"
        @ar_query_condition.bind_vars << value_for_query
      end
      
      def add_equality_condition
        @ar_query_condition.sqls << "#{table_name}.#{@name} = ?"
        @ar_query_condition.bind_vars << value_for_query
      end
      
      def add_range_condition
        if lower_limit = @search.send(@name)[:gt]
          @ar_query_condition.sqls << "#{table_name}.#{@name} > ?"
          @ar_query_condition.bind_vars << lower_limit
        end
        if upper_limit = @search.send(@name)[:lt]
          @ar_query_condition.sqls << "#{table_name}.#{@name} < ?"
          @ar_query_condition.bind_vars << upper_limit
        end
      end
      
      def compare_to_range?
        @search.compare_to_range? @name
      end
      
      def comparator
        @search.comparator @name
      end
      
      def column_is_a_string_type?
        ![:boolean, :integer].include?(@field_type)
      end
      
      def run
        if @search.blank?(@name)
          add_blank_condition
        else
          unless value_for_query.nil?
            if comparator
              add_comparative_condition
            elsif compare_to_range?
              add_range_condition
            elsif column_is_a_string_type?
              add_case_insensitive_string_comparison
            else
              add_equality_condition
            end
          end
        end
      end
      
      def table_name
        @search.model_class.table_name
      end
      
      def value_for_query
        @search.send @name
      end
    end
    
    class FormView < AdminAssistant::Column::View
      include AdminAssistant::Column::FormViewMethods
      
      def check_box_html(form)
        form.check_box name
      end
      
      def date_select_html(form)
        form.date_select(
          name, {:include_blank => true}.merge(@date_select_options)
        )
      end
      
      def datetime_select_html(form)
        opts = {:include_blank => true}.merge @datetime_select_options
        h = form.datetime_select name, opts
        if opts[:include_blank]
          js_name = "#{form.object.class.name.underscore}_#{name}"
          name = @clear_link || "Clear"
          h << @action_view.send(
            :link_to, name, '#',
            'data-prefix' => js_name, :class => 'clear_datetime_select'
          )
        end
        h
      end
      
      def default_html(form)
        input = @input || default_input
        self.send("#{input}_html", form)
      end
      
      def default_input
        if AdminAssistant.default_inputs[@column.field_type]
          AdminAssistant.default_inputs[@column.field_type]
        else
          case @column.field_type
            when :boolean
              :check_box
            when :date
              :date_select
            when :datetime
              :datetime_select
            when :text
              :text_area
            else
              :text_field
            end
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

      def select_html(form)
        if @select_choices
          form.select name, @select_choices, @select_options
        else
          value = form.object.send name
          selected = if value
            '1'
          elsif value == false
            '0'
          end
          form.select(
            name, [[true, '1'], [false, '0']],
            @select_options.merge(:selected => selected)
          )
        end
      end
      
      def text_area_html(form)
        form.text_area name, @text_area_options
      end
      
      def text_field_html(form)
        form.text_field name
      end
      
      def us_state_html(form)
        form.select(
          name, ordered_us_state_names_and_codes, :include_blank => true
        )
      end
    end
    
    class IndexView < AdminAssistant::Column::View
      include AdminAssistant::Column::IndexViewMethods

      def ajax_toggle?
        @column.field_type == :boolean && @ajax_toggle_allowed
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
        @action_view.link_to(
          string(record),
          {
            :action => 'update', :id => record.id, :from => div_id,
            record.class.name.underscore.to_sym => {
              name => (!value(record) ? '1' : '0')
            }
          },
          {:class => 'toggle', :rel => 'nofollow', 'data-method' => 'put'}
        )
      end
      
      def unconfigured_html(record)
        if ajax_toggle?
          ajax_toggle_html(record)
        else
          @action_view.send(:h, string(record))
        end
      end
    end
    
    class SearchView < AdminAssistant::Column::View
      include AdminAssistant::Column::SimpleColumnSearchViewMethods
    end
  end
end
