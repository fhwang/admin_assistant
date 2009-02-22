class AdminAssistant
  module Request    
    class Base
      def initialize(admin_assistant, controller)
        @admin_assistant, @controller = admin_assistant, controller
        @controller.instance_variable_set :@admin_assistant, @admin_assistant
      end
      
      def action
        self.class.name.split(/::/).last.downcase
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
    end
    
    class Create < Base
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
          model_class.column_names
        end
      end
    end
    
    class New < Base
      def call
        @controller.instance_variable_set :@record, model_class.new
        render_new
      end
    end
    
    class Update < Base
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
