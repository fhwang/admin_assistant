class AdminAssistant
  class Builder
    attr_reader :admin_assistant
    
    def initialize(admin_assistant)
      @admin_assistant = admin_assistant
    end
    
    def actions(*a)
      if a.empty?
        @admin_assistant.actions
      else
        @admin_assistant.actions = a
      end
    end
    
    def label(column, label)
      @admin_assistant.custom_column_labels[column.to_s] = label
    end
      
    def form
      yield @admin_assistant.form_settings
    end
      
    def index
      yield @admin_assistant.index_settings
    end
  end
  
  class Settings
    attr_reader :column_names
    
    def initialize(admin_assistant)
      @admin_assistant = admin_assistant
    end
    
    def columns(*args)
      @column_names = args
    end
  end
  
  class FormSettings < Settings
    attr_reader :inputs, :submit_buttons
    
    def initialize(admin_assistant)
      super
      @inputs = {}
      @submit_buttons = []
      @read_only = []
    end
    
    def read_only(*args)
      if args.empty?
        @read_only
      else
        args.each do |arg| @read_only << arg.to_s; end
      end
    end
  end
  
  class IndexSettings < Settings
    attr_reader :actions, :search_fields, :sort_by
    attr_accessor :total_entries
    
    def initialize(admin_assistant)
      super
      @actions = {}
      @sort_by = 'id desc'
      @boolean_labels = {}
      @search_fields = []
    end
    
    def boolean_labels(*args)
      if args.size == 1
        args.first.each do |column_name, pairs|
          @boolean_labels[column_name.to_s] = pairs
        end
      else
        @boolean_labels
      end
    end
    
    def conditions(&block)
      block ? (@conditions = block) : @conditions
    end
    
    def search(*fields)
      @search_fields = fields
    end
    
    def sort_by(*sb)
      if sb.empty?
        @sort_by
      else
        @sort_by = sb
      end
    end
  end
end
