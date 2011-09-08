class AdminAssistant
  class BelongsToColumn < Column
    attr_reader :match_text_fields_in_search
    
    def initialize(belongs_to_assoc, opts)
      @belongs_to_assoc = belongs_to_assoc
      @match_text_fields_in_search = opts[:match_text_fields_in_search]
      @sort_by = opts[:sort_by]
      @association_target = AssociationTarget.new associated_class
    end

    def sort_possible? total_entries
      total_entries < 100_000
    end
    
    def add_to_query_condition(ar_query_condition, search)
      if @match_text_fields_in_search
        add_to_query_condition_by_matching_text_fields(
          ar_query_condition, search
        )
      elsif value = search.send(association_foreign_key)
        ar_query_condition.sqls << "#{association_foreign_key} = ?"
        ar_query_condition.bind_vars << value
      end
    end
    
    def add_to_query_condition_by_matching_text_fields(
          ar_query_condition, search
        )
      if (value = search.send(name)) and !value.blank?
        ar_query_condition.ar_query.joins << name.to_sym
        searchable_columns = Model.new(associated_class).searchable_columns
        ar_query_condition.add_condition do |sub_cond|
          sub_cond.boolean_join = :or
          searchable_columns.each do |column|
            sub_cond.sqls <<
                "LOWER(#{associated_class.table_name}.#{column.name}) like LOWER(?)"
            sub_cond.bind_vars << "%#{value}%"
          end
        end
      end
    end

    def associated_class
      @belongs_to_assoc.klass
    end
    
    def association_foreign_key
      @belongs_to_assoc.options[:foreign_key] ||
          @belongs_to_assoc.association_foreign_key
    end
      
    def attributes_for_search_object(search_params, compare_to_range)
      atts = {}
      if @match_text_fields_in_search
        atts[name.to_sym] = search_params[name]
      else
        terms = search_params[association_foreign_key]
        associated_id = terms.to_i unless terms.blank?
        atts[association_foreign_key.to_sym] = associated_id
        atts[name.to_sym] = if associated_id
          associated_class.find associated_id
        end
      end
      atts
    end
    
    def contains?(column_name)
      column_name.to_s == name
    end
    
    def default_name_method
      @association_target.default_name_method
    end
    
    def name
      @belongs_to_assoc.name.to_s
    end
    
    def order_sql_field
      if @sort_by
        "#{@belongs_to_assoc.table_name}.#{@sort_by}"
      elsif default_name_method
        "#{@belongs_to_assoc.table_name}.#{default_name_method.to_s}"
      else
        "#{@belongs_to_assoc.active_record.table_name}.#{@belongs_to_assoc.association_foreign_key}"
      end
    end
      
    def value_for_search_object(search_params)
      if @match_text_fields_in_search
        search_params[name]
      else
        terms = search_params[association_foreign_key]
        associated_id = terms.to_i unless terms.blank?
        if associated_id
          associated_class.find(associated_id)
        end
      end
    end
    
    class View < AdminAssistant::Column::View
      def initialize(column, action_view, admin_assistant, opts = {})
        super
        @association_target = AssociationTarget.new associated_class
      end
      
      def assoc_value(assoc_value)
        @association_target.assoc_value assoc_value
      end
      
      def associated_class
        @column.associated_class
      end
      
      def association_foreign_key
        @column.association_foreign_key
      end
      
      def value(record)
        assoc_value record.send(name)
      end
    
      def options_for_select
        @association_target.options_for_select
      end
    end
    
    class FormView < View
      include AdminAssistant::Column::FormViewMethods
      
      def default_html(form)
        if associated_class.count > 15
          render_autocompleter form
        else
          form.select(
            association_foreign_key, options_for_select, @select_options
          )
        end
      end
      
      def errors(record)
        record.errors[@column.association_foreign_key]
      end
      
      def render_autocompleter(form)
        @action_view.send(
          :render,
          :file => AdminAssistant.template_file('_token_input'),
          :use_full_path => false,
          :locals => {
            :form => form, :column => @column,
            :select_options => @select_options
          }
        )
      end
    end

    class IndexView < View
      include AdminAssistant::Column::IndexViewMethods
    end
    
    class SearchView < View
      include AdminAssistant::Column::SearchViewMethods
      
      def html(form)
        input = if @column.match_text_fields_in_search
          form.text_field(name)
        elsif associated_class.count > 15
          render_autocompleter form
        else
          form.select(
            association_foreign_key, options_for_select,
            :include_blank => true
          )
        end
        "<p><label>#{label}</label> <br/>#{input}</p>"
      end
      
      def render_autocompleter(form)
        @action_view.send(
          :render,
          :file => AdminAssistant.template_file('_token_input'),
          :use_full_path => false,
          :locals => {
            :form => form, :column => @column,
            :select_options => {:include_blank => true},
            :palette_clones_input_width => false
          }
        )
      end
    end
    
    class ShowView < View
      include AdminAssistant::Column::ShowViewMethods
    end
  end
end
