class AdminAssistant
  class Builder
    attr_reader :admin_assistant
    
    def initialize(admin_assistant)
      @admin_assistant = admin_assistant
    end

    def [](column_name)
      ColumnConfigLookup.new(
        column_name,
        [@admin_assistant.base_settings, form, index, show, index.search], 
        @admin_assistant
      )
    end
    
    def actions(*a)
      if a.empty?
        @admin_assistant.actions
      else
        @admin_assistant.actions = a
      end
    end
    
    def destroy(&block)
      @admin_assistant.custom_destroy = block
    end
      
    def form
      f = @admin_assistant.form_settings
      block_given? ? yield(f) : f
    end
      
    def index
      i = @admin_assistant.index_settings
      block_given? ? yield(i) : i
    end
    
    def model_class_name=(mcn)
      @admin_assistant.model_class_name = mcn
    end
    
    def show
      @admin_assistant.show_settings
    end
    
    class ColumnConfigLookup
      def initialize(column_name, settingses, admin_assistant)
        @column_name, @settingses, @admin_assistant =
            column_name, settingses, admin_assistant
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
    
    def method_missing(meth, *args, &block)
      if field_type = @fields_config[meth]
        if field_type == :accessor
          return @values[meth]
        elsif field_type == :boolean
          return @values[meth] = true
        elsif field_type == :block
          if block
            return @values[meth] = block
          else
            return @values[meth]
          end
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
  
  class AbstractSettings
    attr_reader :column_names, :column_configs
    
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
  
  class BaseSettings < AbstractSettings
    def column_config_args
      {:boolean_labels => :accessor, :label => :accessor,
       :polymorphic_types => :accessor}
    end
  end
  
  class FormSettings < AbstractSettings
    attr_reader :submit_buttons
    
    def initialize(admin_assistant)
      super
      @submit_buttons = []
    end
    
    def column_config_args
      {:datetime_select_options => :accessor,
       :date_select_options => :accessor, :default => :block,
       :description => :accessor, :exclude_blank => :boolean,
       :input => :accessor, :nilify_link => :accessor, :read_only => :boolean,
       :write_once => :boolean, :select_options => :accessor
      }
    end
    
    def columns_for_edit(*args)
      if args.empty?
        @columns_for_edit || column_names
      else
        @columns_for_edit = args
      end
    end
    
    def columns_for_new(*args)
      if args.empty?
        @columns_for_new || column_names
      else
        @columns_for_new = args
      end
    end
    
    def column_names
      @column_names || @admin_assistant.default_column_names
    end
  end
  
  class IndexSettings < AbstractSettings
    attr_reader :actions, :right_column_links, :search_settings, :sort_by
    
    def initialize(admin_assistant)
      super
      @actions = {}
      @right_column_links = []
      @search_fields = []
      @search_settings = SearchSettings.new @admin_assistant
      @sort_by = "#{admin_assistant.model_class.table_name}.id desc"
    end
    
    def column_config_args
      {:image_size => :accessor, :link_to_args => :block}
    end
    
    def conditions(str = nil, &block)
      if str.nil? && block.nil?
        @conditions
      elsif str
        @conditions = str
      elsif block
        @conditions = block
      end
    end
    
    def header(&block)
      block ? (@header = block) : @header
    end
    
    def include(*associations)
      if associations.empty?
        @include
      else
        @include = associations
      end
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
    
    def total_entries(&block)
      block ? (@total_entries = block) : @total_entries
    end
    
    class SearchSettings < AbstractSettings
      attr_reader :column_names
      
      def initialize(admin_assistant)
        super
        @column_names = []
        @default_search_includes = []
      end
      
      def column_config_args
        {:match_text_fields_for_association => :boolean}
      end
      
      def columns(*c)
        @column_names = c
      end
    
      def default_search_includes(*includes)
        if includes.empty?
          @default_search_includes
        else
          @default_search_includes = includes
        end
      end
    end
  end
  
  class ShowSettings < AbstractSettings
    def column_config_args
      {}
    end
  end
end
