class AdminAssistant
  module Request
    class Base
      def initialize(admin_assistant, controller)
        @admin_assistant, @controller = admin_assistant, controller
      end
      
      def action
        self.class.name.split(/::/).last.downcase
      end
      
      def columns_from_active_record(ar_columns)
        ar_columns.map { |ar_column| ActiveRecordColumn.new(ar_column) }
      end
      
      def columns_from_config(form_config)
        form_config.map { |column_sym|
          if ar_column = model_class.columns_hash[column_sym.to_s]
            ActiveRecordColumn.new ar_column
          else
            AdminAssistantColumn.new column_sym
          end
        }
      end
      
      def model_class
        @admin_assistant.model_class
      end
    
      def model_class_symbol
        model_class.name.underscore.to_sym
      end
      
      def params_for_save
        params = {}
        @controller.params[model_class_symbol].each do |k, v|
          if filter = @admin_assistant.params_filter_for_save[k.to_sym]
            params[k] = filter.call v
          elsif @record.respond_to?("#{k}=")
            params[k] = v
          end
        end
        params
      end
      
      def redirect_after_save
        url_params = if @admin_assistant.destination_after_save
          @admin_assistant.destination_after_save.call @controller, @record
        end
        url_params ||= {:action => 'index'}
        @controller.send :redirect_to, url_params
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
      
      def save
        if @admin_assistant.before_save
          @admin_assistant.before_save.call(@record, @controller.params)
        end
        @record.save
      end
    
      def template_file(template_name = action)
        "#{RAILS_ROOT}/vendor/plugins/admin_assistant/lib/views/#{template_name}.html.erb"
      end
    end
    
    module FormMethods
      def columns
        if form_config = @admin_assistant.request_configs[:form][:columns]
          columns_from_config form_config
        else
          columns_from_active_record(
            model_class.columns.reject { |ar_column|
              %w(id created_at updated_at).include?(ar_column.name)
            }
          )
        end
      end
    end
    
    class Create < Base
      include FormMethods
      
      def call
        @record = model_class.new
        @record.attributes = params_for_save
        if save
          redirect_after_save
        else
          @controller.instance_variable_set :@record, @record
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
      
      def columns
        if index_config = @admin_assistant.request_configs[:index][:columns]
          columns_from_config index_config
        else
          columns_from_active_record model_class.columns
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
        if save
          redirect_after_save
        else
          @controller.instance_variable_set :@record, @record
          render_edit
        end
      end
    end
  end
end
