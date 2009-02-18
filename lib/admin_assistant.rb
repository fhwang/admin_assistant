class AdminAssistant
  attr_accessor :model_class
  
  def initialize(model_class)
    @model_class = model_class
  end
  
  def method_missing(meth, *args)
    request_methods = [:create, :edit, :index, :new, :update]
    if request_methods.include?(meth) and args.size == 1
      Request.const_get(meth.to_s.capitalize).new(model_class, *args).call
    else
      super
    end
  end
  
  module ControllerMethods
    def self.included(controller)
      controller.extend ControllerClassMethods
      controller.cattr_accessor :admin_assistant
    end
    
    def create
      self.class.admin_assistant.create self
    end
    
    def edit
      self.class.admin_assistant.edit self
    end
  
    def index
      self.class.admin_assistant.index self
    end
    
    def new
      self.class.admin_assistant.new self
    end
    
    def update
      self.class.admin_assistant.update self
    end
  end
  
  module ControllerClassMethods
    def admin_assistant_for(model_class)
      self.admin_assistant = AdminAssistant.new(model_class)
    end
  end
  
  module Request
    class Base
      attr_reader :model_class
      
      def initialize(model_class, controller)
        @model_class, @controller = model_class, controller
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
    
      def template_file(a = action)
        "#{RAILS_ROOT}/vendor/plugins/admin_assistant/lib/views/#{a}.html.erb"
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
          @controller.send(
            :render, :file => template_file('new'), :layout => true
          )
        end
      end
    end
    
    class Edit < Base
      def call
        @controller.instance_variable_set(
          :@record, model_class.find(@controller.params[:id])
        )
        @controller.send(
          :render, :file => template_file, :layout => true
        )
      end
    end
    
    class Index < Base
      def call
        @controller.instance_variable_set(
          :@records, model_class.find(:all, :limit => 25, :order => 'id desc')
        )
        @controller.send(
          :render, :file => template_file, :layout => true
        )
      end
    end
    
    class New < Base
      def call
        @controller.instance_variable_set :@record, model_class.new
        @controller.send(
          :render, :file => template_file, :layout => true
        )
      end
    end
    
    class Update < Base
      def call
        record = model_class.find @controller.params[:id]
        record.attributes = @controller.params[model_class_symbol]
        if record.save
          @controller.send :redirect_to, :action => 'index'
        else
          @controller.instance_variable_set :@record, record
          @controller.send(
            :render, :file => template_file('edit'), :layout => true
          )
        end
      end
    end
  end
  
  class Search
    attr_accessor :terms
    
    # stop form_for from complaining, it thinks this is a model
    def id
    end
  end
end
