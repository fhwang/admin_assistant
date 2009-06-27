class AdminAssistant
  class Search
    attr_reader :params
    
    def initialize(admin_assistant, params)
      @admin_assistant, @params = admin_assistant, params
      @params ||= {}
      @attributes = HashWithIndifferentAccess.new
      columns.each do |c|
        c.attributes_for_search_object(@params).each do |key, value|
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
    
    def columns
      column_names = settings.column_names
      if column_names.empty?
        [DefaultSearchColumn.new(@admin_assistant.model_class)]
      else
        column_names.map { |column_name| 
          @admin_assistant.column(column_name.to_s)
        }
      end
    end
    
    def column_views(action_view)
      columns.map { |c|
        opts = {:search => self}
        if c.respond_to?(:name) && c.name
          opts[:boolean_labels] = @admin_assistant[c.name].boolean_labels
          opts[:label] = @admin_assistant[c.name].label
          opts[:polymorphic_types] = @admin_assistant[c.name].polymorphic_types
        end
        c.search_view action_view, opts
      }
    end
    
    def id
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
  
    def settings
      @admin_assistant.search_settings
    end
  end
end
