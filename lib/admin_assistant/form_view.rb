class AdminAssistant
  module FormViewMethods
    def action
      if %w(new create).include?(controller.action_name)
        'create'
      else
        'update'
      end
    end
    
    def controller
      @action_view.controller
    end
  end
  
  class FormView
    include FormViewMethods
    
    attr_reader :record
    
    def initialize(record, admin_assistant, action_view)
      @record, @admin_assistant, @action_view =
          record, admin_assistant, action_view
    end
    
    def column_names
      if %w(new create).include?(@action_view.action_name)
        settings.columns_for_new
      elsif %w(edit update).include?(@action_view.action_name)
        settings.columns_for_edit
      end
    end
    
    def columns
      @admin_assistant.accumulate_columns(column_names).map { |c|
        c.form_view @action_view, @admin_assistant
      }
    end
    
    def extra_submit_buttons
      settings.submit_buttons
    end
    
    def form_for_args
      args = {:url => {:action => action, :id => @record.id}}
      unless @admin_assistant.paperclip_attachments.empty? &&
             @admin_assistant.file_columns.empty?
        args[:html] = {:multipart => true}
      end
      args
    end
    
    def model_class
      @admin_assistant.model_class
    end
    
    def settings
      @admin_assistant.form_settings
    end
    
    def submit_value
      action.capitalize
    end
    
    def title
      (@record.id ? "Edit" : "New") + " #{@admin_assistant.model_class_name}"
    end
  end
  
  class MultiFormView
    include FormViewMethods
    
    def initialize(records, admin_assistant, action_view)
      @records, @admin_assistant, @action_view =
          records, admin_assistant, action_view
      @sub_form_views = @records.map { |record|
        AdminAssistant::FormView.new(record, @admin_assistant, @action_view)
      }
    end
    
    def columns
      @sub_form_views.first.columns
    end
    
    def extra_submit_buttons
      @sub_form_views.first.extra_submit_buttons
    end
    
    def form_for_args
      [
        @records.first.class.name.underscore.to_sym,
        @records,
        {
          :url => {:action => action},
          :builder => AdminAssistant::MultiFormView::Builder,
          :sub_form_views => @sub_form_views
        }
      ]
    end
    
    def submit_value
      @sub_form_views.first.submit_value
    end
    
    def title
      @sub_form_views.first.title
    end
    
    class Builder < ::ActionView::Helpers::FormBuilder
      def initialize(object_name, object, template, options, proc)
        super(object_name, object, template, options, proc)
        @sub_form_views = options[:sub_form_views]
      end

      def each_sub_form
        @object.each_with_index do |obj, i|
          builder = SubFormBuilder.new(
            @object_name, obj, @template, @options, @proc, i
          )
          yield builder, @sub_form_views[i]
        end
      end
      
      class SubFormBuilder
        attr_reader :object, :prefix
        
        def initialize(object_name, object, template, options, proc, position)
          @object_name, @object, @template, @options, @proc =
              object_name, object, template, options, proc
          @default_options = @options ? @options.slice(:index) : {}
          @prefix = ('a'..'z').to_a[position]
        end
        
        def method_missing(meth, *args, &block)
          if my_field_helpers.include?(meth.to_s)
            method = args.shift
            options = args.shift || {}
            @template.send(
              meth,
              "#{@object_name}[#{@prefix}]",
              method,
              objectify_options(options)
            )
          else
            super
          end
        end
        
        def my_field_helpers
          ::ActionView::Helpers::FormBuilder.field_helpers -
              %w(label check_box radio_button fields_for) + ['datetime_select']
        end
        
        def objectify_options(options)
          @default_options.merge(options.merge(:object => @object))
        end
      end
    end
  end
end
