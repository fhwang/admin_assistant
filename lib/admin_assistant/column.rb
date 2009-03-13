class AdminAssistant
  module ColumnsMethods
    def belongs_to_columns
      columns.select { |c| c.is_a?(BelongsToColumn) }
    end
    
    def column_from_name(name)
      ar_column = @admin_assistant.model_class.columns_hash[name.to_s]
      column = if ar_column
        ActiveRecordColumn.new(ar_column)
      else
        associations = model_class.reflect_on_all_associations
        if belongs_to_assoc = associations.detect { |assoc|
          assoc.macro == :belongs_to && assoc.name.to_s == name.to_s
        }
          BelongsToColumn.new(belongs_to_assoc)
        else
          AdminAssistantColumn.new(name)
        end
      end
      if column && (custom = @admin_assistant.custom_column_labels[name.to_s])
        column.custom_label = custom
      end
      column
    end
    
    def column_name_or_assoc_name(name)
      result = name
      ar_column = model_class.columns_hash[name.to_s]
      if ar_column
        associations = model_class.reflect_on_all_associations
        if belongs_to_assoc = associations.detect { |assoc|
          assoc.macro == :belongs_to && assoc.association_foreign_key == name
        }
          result = belongs_to_assoc.name.to_s
        end
      end
      result
    end
    
    def columns
      column_names = @admin_assistant.send(
        "#{self.class.name.split(/::/).last.gsub(/View/,'').downcase}_settings"
      ).column_names
      column_names = default_column_names unless column_names
      columns = paperclip_attachments.map { |paperclip_attachment|
        PaperclipColumn.new paperclip_attachment
      }
      column_names.each do |column_name|
        if columns.all? { |column| !column.contains?(column_name) }
          column = column_from_name column_name
          columns << column if column
        end
      end
      columns
    end
    
    def model_class
      @admin_assistant.model_class
    end
    
    def paperclip_attachments
      pa = []
      if model_class.respond_to?(:attachment_definitions)
        if model_class.attachment_definitions
          pa = model_class.attachment_definitions.map { |name, definition|
            name
          }
        end
      end
      pa
    end
  end
  
  class Column
    attr_accessor :custom_label, :sort_order

    def view(action_view)
      klass = self.class.const_get 'View'
      klass.new self, action_view
    end
  
    class View < Delegator
      def initialize(column, action_view)
        super(column)
        @column, @action_view = column, action_view
      end
      
      def __getobj__
        @column
      end
      
      def __setobj__(column)
        @column = column
      end
      
      def index_header_css_class
        "sort #{sort_order}" if sort_order
      end
      
      def index_td_css_class
        'sort' if sort_order
      end
      
      def label
        if @column.custom_label
          @column.custom_label
        elsif @column.name.to_s == 'id'
          'ID'
        else
          @column.name.to_s.capitalize.gsub(/_/, ' ') 
        end
      end
      
      def paperclip?
        @column.is_a?(PaperclipColumn)
      end
      
      def sort_possible?
        @column.is_a?(ActiveRecordColumn) || @column.is_a?(BelongsToColumn)
      end
    end
  end
  
  class ActiveRecordColumn < Column
    def initialize(ar_column)
      @ar_column = ar_column
    end
    
    def contains?(column_name)
      column_name.to_s == @ar_column.name
    end
    
    def name
      @ar_column.name
    end
    
    def name_for_sort
      name
    end
    
    def sql_type
      @ar_column.type
    end
    
    class View < AdminAssistant::Column::View
      def add_to_form(form)
        case @column.sql_type
          when :text
            form.text_area name
          when :boolean
            form.check_box name
          else
            form.text_field name
          end
      end

      def field_value(record)
        record.send(name) if record.respond_to?(name)
      end
    end
  end
  
  class AdminAssistantColumn < Column
    attr_reader :name
    
    def initialize(name)
      @name = name.to_s
    end
    
    def contains?(column_name)
      column_name.to_s == @name
    end
    
    class View < AdminAssistant::Column::View
      def field_value(record)
        nil
      end
    end
  end
  
  class BelongsToColumn < Column
    def initialize(belongs_to_assoc)
      @belongs_to_assoc = belongs_to_assoc
    end
    
    def associated_class
      @belongs_to_assoc.klass
    end
    
    def association_foreign_key
      @belongs_to_assoc.association_foreign_key
    end
    
    def contains?(column_name)
      column_name.to_s == name
    end
    
    def default_name_method
      [:name, :title, :login, :username].detect { |m|
        associated_class.columns.any? { |column| column.name.to_s == m.to_s }
      }
    end
    
    def name
      @belongs_to_assoc.name.to_s
    end
    
    def name_for_sort
      name
    end
    
    def order_sql_field
      sql = "#{@belongs_to_assoc.table_name}. "
      sql << if default_name_method
        default_name_method.to_s
      else
        @belongs_to_assoc.association_foreign_key
      end
    end
    
    class View < AdminAssistant::Column::View
      def add_to_form(form)
        form.select(
          association_foreign_key,
          associated_class.find(:all).map { |model| 
            [model.send(default_name_method), model.id]
          }
        )
      end
    
      def field_value(record)
        assoc_value = record.send name
        if assoc_value.respond_to?(:name_for_admin_assistant)
          assoc_value.name_for_admin_assistant
        elsif assoc_value && default_name_method
          assoc_value.send default_name_method
        end
      end
    end
  end
  
  class PaperclipColumn < Column
    attr_reader :name
    
    def initialize(name)
      @name = name.to_s
    end
    
    def contains?(column_name)
      column_name.to_s == @name ||
      column_name.to_s =~
          /^#{@name}_(file_name|content_type|file_size|updated_at)$/
    end
    
    class View < AdminAssistant::Column::View
      def add_to_form(form)
        form.file_field name
      end
      
      def index_html(record)
        @action_view.image_tag record.send(@column.name).url
      end
    end
  end
end
