class AdminAssistant
  class Search
    attr_reader :params
    
    def initialize(admin_assistant, params)
      @admin_assistant, @params = admin_assistant, params
      @params ||= {}
      @attributes = HashWithIndifferentAccess.new
      columns.each do |c|
        c.verify_for_search
        compare_to_range = compare_to_range?(c.name) if c.respond_to?(:name)
        attributes = c.attributes_for_search_object(@params, compare_to_range)
        attributes.each do |key, value|
          @attributes[key] = value
        end
      end
    end
    
    def [](name)
      @params[name]
    end
  
    def add_to_query(ar_query)
      unless @params.empty?
        ar_query.add_condition do |cond|
          if match_any_conditions?
            cond.boolean_join = :or
          end
          columns.each do |column|
            column.add_to_query_condition cond, self
          end
        end
      end
    end
    
    def blank?(column_name)
      @params["#{column_name}(blank)"] == '1'
    end
    
    def columns
      column_names = settings.column_names
      if column_names.empty?
        [DefaultSearchColumn.new(
          @admin_assistant.model_class,
          :fields_to_match => @admin_assistant.default_search_matches_on
        )]
      else
        column_names.map { |column_name| 
          @admin_assistant.column(column_name.to_s)
        }
      end
    end
    
    def column_views(action_view)
      columns.map { |c|
        c.search_view action_view, @admin_assistant, :search => self
      }
    end
    
    def comparator(column_name)
      c = @params["#{column_name}(comparator)"]
      c if %w(< <= = >= >).include?(c)
    end
    
    def compare_to_range?(column_name)
      settings[column_name].compare_to_range
    end

    def id
      @attributes[:id] if @attributes.has_key?(:id)
    end
    
    def match_all_conditions?
      !match_any_conditions?
    end
    
    def match_any_conditions?
      @params["(all_or_any)"] == 'any'
    end
    
    def method_missing(meth, *args)
      if @attributes.has_key?(meth)
        @attributes[meth]
      else
        super
      end
    end
    
    def model_class
      @admin_assistant.model_class
    end
  
    def settings
      @admin_assistant.search_settings
    end
  end
end
