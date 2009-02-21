class AdminAssistant
  module Request
    class Base
      attr_reader :model_class
      
      def initialize(model_class, controller, config)
        @model_class, @controller, @config = model_class, controller, config
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
      def call
        record = model_class.new @controller.params[model_class_symbol]
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
        if @config[:columns]
          @config[:columns].map { |c| c.to_s }
        else
          @model_class.column_names
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
        @record.attributes = @controller.params[model_class_symbol]
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
