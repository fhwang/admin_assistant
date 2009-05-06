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
      
    def form
      yield @admin_assistant.form_settings
    end
      
    def index
      i = @admin_assistant.index_settings
      block_given? ? yield(i) : i
    end
    
    def inputs
      @admin_assistant.form_settings.inputs
    end
    
    def label(column, label)
      @admin_assistant.custom_column_labels[column.to_s] = label
    end
    
    def show
      @admin_assistant.show_settings
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
      @write_once = []
    end
    
    def columns_for_edit(*args)
      if args.empty?
        @columns_for_edit
      else
        @columns_for_edit = args
      end
    end
    
    def columns_for_new(*args)
      if args.empty?
        @columns_for_new
      else
        @columns_for_new = args
      end
    end
    
    def read_only(*args)
      if args.empty?
        @read_only
      else
        args.each do |arg| @read_only << arg.to_s; end
      end
    end
    
    def write_once(*args)
      if args.empty?
        @write_once
      else
        args.each do |arg| @write_once << arg.to_s; end
      end
    end
  end
  
  class IndexSettings < Settings
    attr_reader :actions, :image_sizes, :link_to_args, :right_column_links,
                :search_settings, :sort_by
    attr_accessor :total_entries
    
    def initialize(admin_assistant)
      super
      @actions = {}
      @boolean_labels = {}
      @image_sizes = {}
      @link_to_args = {}
      @right_column_links = []
      @search_fields = []
      @search_settings = SearchSettings.new @admin_assistant
      @sort_by = 'id desc'
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
    
    def search(*columns)
      if block_given?
        yield @search_settings
      else
        @search_settings.columns *columns
      end
    end
    
    def sort_by(*sb)
      if sb.empty?
        @sort_by
      else
        @sort_by = sb.first
      end
    end
    
    class SearchSettings < Settings
      attr_reader :column_names, :comparators,
                  :match_text_fields_for_association
      
      def initialize(admin_assistant)
        super
        @column_names = []
        @comparators = {}
        @match_text_fields_for_association = []
      end
      
      def columns(*c)
        @column_names = c
      end
      
      def match_text_fields_for_association(*c)
        if c.empty?
          @match_text_fields_for_association
        else
          @match_text_fields_for_association = c
        end
      end
    end
  end
  
  class ShowSettings < Settings
  end
end
