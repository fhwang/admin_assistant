class AdminAssistant
  class ActiveRecordColumn < Column
    def initialize(ar_column)
      @ar_column = ar_column
    end
    
    def add_to_query_condition(ar_query_condition, search)
      value_for_query =
          attributes_for_search_object(search.params).values.first
      unless value_for_query.nil?
        comp = comparator(search)
        unless %w(< <= = >= >).include?(comp)
          comp = nil
        end
        if comp
          ar_query_condition.sqls << "#{name} #{comp} ?"
          ar_query_condition.bind_vars << value_for_query
        else
          case sql_type
            when :boolean
              ar_query_condition.sqls << "#{name} = ?"
              ar_query_condition.bind_vars << value_for_query
            else
              ar_query_condition.sqls << "#{name} like ?"
              ar_query_condition.bind_vars << "%#{value_for_query}%"
          end
        end
      end
    end
      
    def attributes_for_search_object(search_params)
      terms = search_params[@ar_column.name]
      value = unless terms.blank?
        case sql_type
          when :boolean
            terms.blank? ? nil : (terms == 'true')
          else
            terms
        end
      end
      {name => value}
    end
      
    def comparator(search)
      search.params["#{@ar_column.name}(comparator)"]
    end
    
    def contains?(column_name)
      column_name.to_s == @ar_column.name
    end
    
    def name
      @ar_column.name
    end
    
    def sql_type
      @ar_column.type
    end
    
    class View < AdminAssistant::Column::View
      def value(record)
        record.send(name) if record.respond_to?(name)
      end
    end
    
    class FormView < View
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
          name = @nilify_link || "Set \"#{label.downcase}\" to nil"
          h << @action_view.send(
            :link_to_function, name,
            "AdminAssistant.nilify_datetime_select('#{js_name}')"
          )
        end
        h
      end
      
      def default_input
        case @column.sql_type
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
      
      def html(form)
        input = @input || default_input
        self.send("#{input}_html", form)
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
        # for now only used for boolean fields
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
          string(record),
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
    end
    
    class SearchView < View
      include AdminAssistant::Column::SearchViewMethods
      
      def comparator_html(search)
        comparator_opts = [
          ['greater than', '>'], ['greater than or equal to', '>='],
          ['equal to', '='], ['less than or equal to', '<='],
          ['less than', '<']
        ]
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
      
      def html(form)
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
            input = form.select(name, opts)
          else
            if @column.sql_type == :integer
              input << comparator_html(form.object) << ' '
            end
            input << form.text_field(name)
        end
        "<p><label>#{label}</label> <br/>#{input}</p>"
      end
    end
    
    class ShowView < View
      include AdminAssistant::Column::ShowViewMethods
    end
  end
end
