class AdminAssistant
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
      records = @associated_class.find(:all)
      name_method = default_name_method
      if name_method.nil? and
         records.first.respond_to?(:name_for_admin_assistant)
        name_method = :name_for_admin_assistant
      end
      sort_value_method = nil
      if records.first.respond_to?(:sort_value_for_admin_assistant)
        sort_value_method = :sort_value_for_admin_assistant
      else
        sort_value_method = name_method
      end
      if sort_value_method
        records = records.sort_by { |model| model.send(sort_value_method) }
      end
      if name_method
        records.map { |model| [model.send(name_method), model.id] }
      else
        records.map &:id
      end
    end
  end
end
