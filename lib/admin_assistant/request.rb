class AdminAssistant
  module Request
    module FormMethods
      def columns
        if from_config = @admin_assistant.request_configs[:form][:columns]
          from_config.map { |column_sym|
            if ar_column = model_class.columns_hash[column_sym.to_s]
              ActiveRecordColumn.new ar_column
            else
              AdminAssistantColumn.new column_sym
            end
          }
        else
          model_class.columns.reject { |ar_column|
            %w(id created_at updated_at).include?(ar_column.name)
          }.map { |ar_column| ActiveRecordColumn.new(ar_column) }
        end
      end
      
      class ActiveRecordColumn < Delegator
        def initialize(ar_column)
          super
          @ar_column = ar_column
        end
        
        def __getobj__
          @ar_column
        end
        
        def html_for_form(form)
          case type
            when :text
              form.text_area name
            else
              form.text_field name
            end
        end
        
        def type
          @ar_column.type
        end
      end
      
      class AdminAssistantColumn
        attr_reader :name
        
        def initialize(name)
          @name = name
        end
        
        def html_for_form(form)
          form.text_field name
        end
      end
    end
    
    class Base
      attr_reader :model_class
      
      def initialize(admin_assistant, model_class, controller)
        @admin_assistant, @model_class, @controller =
            admin_assistant, model_class, controller
        @controller.instance_variable_set :@admin_assistant_request, self
      end
      
      def action
        self.class.name.split(/::/).last.downcase
      end
    
      def model_class_name
        model_class.name.gsub(/([A-Z])/, ' \1')[1..-1].downcase
      end
    
      def model_class_symbol
        model_class.name.underscore.to_sym
      end
      
      def params_for_save
        params = {}
        @controller.params[model_class_symbol].each do |k, v|
          if filter = @admin_assistant.params_filter_for_save[k.to_sym]
            params[k] = filter.call v
          else
            params[k] = v
          end
        end
        params
      end
      
      def render_edit
        render_template_file(
          'form', :locals => {:action => 'update', :id => @record.id}
        )
      end

      def render_new
        render_template_file 'form', :locals => {:action => 'create'}
      end
      
      def render_template_file(template_name = action, options_plus = {})
        options = {:file => template_file(template_name), :layout => true}
        options = options.merge options_plus
        @controller.send(:render, options)
      end
    
      def template_file(template_name = action)
        "#{RAILS_ROOT}/vendor/plugins/admin_assistant/lib/views/#{template_name}.html.erb"
      end
  
      def url_params(a = action)
        {:controller => @controller.controller_name, :action => a}
      end
    end
    
    class Create < Base
      include FormMethods
      
      def call
        record = model_class.new params_for_save
        if record.save
          @controller.send :redirect_to, :action => 'index'
        else
          @controller.instance_variable_set :@record, record
          render_new
        end
      end
    end
    
    class Edit < Base
      include FormMethods
      
      def call
        @record = model_class.find @controller.params[:id]
        @controller.instance_variable_set :@record, @record
        render_edit
      end
    end
    
    class Index < Base
      def call
        index = AdminAssistant::Index.new(model_class, @controller.params)
        @controller.instance_variable_set :@index, index
        render_template_file
      end
      
      def column_names
        if columns = @admin_assistant.request_configs[:index][:columns]
          columns.map { |c| c.to_s }
        else
          @model_class.column_names
        end
      end
    end
    
    class New < Base
      include FormMethods
      
      def call
        @controller.instance_variable_set :@record, model_class.new
        render_new
      end
    end
    
    class Update < Base
      include FormMethods
      
      def call
        @record = model_class.find @controller.params[:id]
        @record.attributes = params_for_save
        if @record.save
          @controller.send :redirect_to, :action => 'index'
        else
          @controller.instance_variable_set :@record, @record
          render_edit
        end
      end
    end
  end
end
