class AdminAssistant
  module Request
    class Base
      def initialize(admin_assistant, controller)
        @admin_assistant, @controller = admin_assistant, controller
      end
  
      def action
        @controller.action_name
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
          from_form_method = "#{k}_from_form".to_sym
          if @controller.respond_to?(from_form_method)
            params[k] = @controller.send(from_form_method, v)
          elsif @record.respond_to?("#{k}=")
            params[k] = v
          end
        end
        params
      end
      
      def redirect_after_save
        url_params = if @controller.respond_to?(:destination_after_save)
          @controller.send(
            :destination_after_save, @record, @controller.params
          )
        end
        url_params ||= {:action => 'index'}
        @controller.send :redirect_to, url_params
      end
      
      def render_edit
        render_form 'update'
      end
      
      def render_form(action)
        options = {
          :file => template_file('form'), :layout => true,
          :locals => {:form => Form.new(@record, action, @admin_assistant)}
        }
        html = @controller.send(:render_to_string, options)
        after_form_html_template = File.join(
          RAILS_ROOT, 'app/views/', @controller.controller_path, 
          '_after_form.html.erb'
        )
        if File.exist?(after_form_html_template)
          html << @controller.send(
            :render_to_string,
            :file => after_form_html_template, :layout => false
          )
        end
        @controller.send :render, :text => html
      end

      def render_new
        render_form 'create'
      end
      
      def render_template_file(template_name = action, options_plus = {})
        options = {:file => template_file(template_name), :layout => true}
        options = options.merge options_plus
        @controller.send(:render, options)
      end
      
      def save
        if @controller.respond_to?(:before_save)
          @controller.send(:before_save, @record, @controller.params)
        end
        @record.save
      end
    
      def template_file(template_name = action)
        "#{RAILS_ROOT}/vendor/plugins/admin_assistant/lib/views/#{template_name}.html.erb"
      end
    end
    
    class Create < Base
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
      def call
        @record = model_class.find @controller.params[:id]
        @controller.instance_variable_set :@record, @record
        render_edit
      end
    end
    
    class Index < Base
      def call
        index = AdminAssistant::Index.new(@admin_assistant, @controller.params)
        @controller.instance_variable_set :@index, index
        render_template_file
      end
      
      def columns
        @admin_assistant.index_settings.columns
      end
    end
    
    class New < Base
      def call
        @record = model_class.new
        @controller.instance_variable_set :@record, @record
        render_new
      end
    end
    
    class Update < Base
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
  
  class Form
    include ColumnsMethods

    def initialize(record, action, admin_assistant)
      @record, @action, @admin_assistant = record, action, admin_assistant
    end
    
    def columns
      specified_columns = @admin_assistant.form_settings.columns
      if specified_columns
        columns_from_settings specified_columns
      else
        columns_from_active_record(
          @admin_assistant.model_class.columns.reject { |ar_column|
            %w(id created_at updated_at).include?(ar_column.name)
          }
        )
      end
    end
    
    def extra_submit_buttons
      @admin_assistant.form_settings.submit_buttons
    end
    
    def submit_value
      @action.capitalize
    end
    
    def title
      (@record.id ? "Edit" : "New") + " #{@admin_assistant.model_class_name}"
    end
    
    def url_opts
      {:action => @action, :id => @record.id}
    end
  end
end
