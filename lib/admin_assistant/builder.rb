class AdminAssistant
  class Builder
    attr_reader :admin_assistant
    
    def initialize(admin_assistant)
      @admin_assistant = admin_assistant
    end

    def [](column_name)
      ColumnConfigLookup.new(column_name, [form, index, show, index.search])
    end
    
    def actions(*a)
      if a.empty?
        @admin_assistant.actions
      else
        @admin_assistant.actions = a
      end
    end
      
    def form
      f = @admin_assistant.form_settings
      block_given? ? yield(f) : f
    end
      
    def index
      i = @admin_assistant.index_settings
      block_given? ? yield(i) : i
    end
    
    def label(column, label)
      @admin_assistant.custom_column_labels[column.to_s] = label
    end
    
    def show
      @admin_assistant.show_settings
    end
    
    class ColumnConfigLookup
      def initialize(column_name, settingses)
        @column_name, @settingses = column_name, settingses
      end
      
      def method_missing(meth, *args)
        match = meth
        if match.to_s =~ /^(.*)=$/
          match = $1.to_sym
        elsif match.to_s =~ /^(.*)\?$/
          match = $1.to_sym
        end
        setting = @settingses.detect { |setting|
          setting.column_config_args.keys.include?(match)
        }
        if setting
          setting[@column_name].send(meth, *args)
        else
          super
        end
      end
    end
  end
  
  class ColumnConfig
    def initialize(fields_config)
      @fields_config = fields_config
      @values = {}
    end
    
    def method_missing(meth, *args)
      if field_type = @fields_config[meth]
        if field_type == :accessor
          return @values[meth]
        elsif field_type == :boolean
          return @values[meth] = true
        end
      elsif meth.to_s =~ /=$/
        field_name, field_type = @fields_config.detect { |fn, ft|
          meth.to_s =~ /^#{fn}=$/
        }
        if field_type == :accessor
          return @values[field_name] = args.first
        end
      elsif meth.to_s =~ /\?$/
        field_name, field_type = @fields_config.detect { |fn, ft|
          meth.to_s =~ /^#{fn}\?$/
        }
        if field_type == :boolean
          return !@values[field_name].nil?
        end
      end
      super
    end
  end
  
  class Settings
    attr_reader :column_names
    
    def initialize(admin_assistant)
      @admin_assistant = admin_assistant
      @column_configs = HashWithIndifferentAccess.new { |h, k|
        h[k] = ColumnConfig.new(column_config_args)
      }
    end
    
    def [](column_name)
      @column_configs[column_name]
    end
    
    def columns(*args)
      @column_names = args
    end
  end
  
  class FormSettings < Settings
    attr_reader :submit_buttons
    
    def initialize(admin_assistant)
      super
      @submit_buttons = []
    end
    
    def column_config_args
      {:description => :accessor, :input => :accessor, :read_only => :boolean, 
       :write_once => :boolean}
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
  end
  
  class IndexSettings < Settings
    attr_reader :actions, :right_column_links, :search_settings, :sort_by
    attr_accessor :total_entries
    
    def initialize(admin_assistant)
      super
      @actions = {}
      @right_column_links = []
      @search_fields = []
      @search_settings = SearchSettings.new @admin_assistant
      @sort_by = 'id desc'
    end
    
    def column_config_args
      {:boolean_labels => :accessor, :image_size => :accessor,
       :link_to_args => :accessor}
    end
    
    def conditions(&block)
      block ? (@conditions = block) : @conditions
    end
    
    def search(*columns)
      if block_given?
        yield @search_settings
      elsif columns.empty?
        @search_settings
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
      attr_reader :column_names
      
      def initialize(admin_assistant)
        super
        @column_names = []
      end
      
      def column_config_args
        {:comparators => :accessor,
         :match_text_fields_for_association => :boolean}
      end
      
      def columns(*c)
        @column_names = c
      end
    end
  end
  
  class ShowSettings < Settings
    def column_config_args
      {}
    end
  end
end
