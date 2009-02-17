class AdminAssistant
  attr_accessor :model_class
  
  def initialize(model_class, controller_class)
    @model_class, @controller_class = model_class, controller_class
  end
  
  def create(controller)
    record = @model_class.new controller.params[model_class_symbol]
    if record.save
      controller.send :redirect_to, :action => 'index'
    else
      controller.instance_variable_set :@admin_assistant, self
      controller.instance_variable_set :@record, record
      controller.send :render, :file => template_file('new'), :layout => true
    end
  end
  
  def edit(controller)
    controller.instance_variable_set :@admin_assistant, self
    controller.instance_variable_set(
      :@record, model_class.find(controller.params[:id])
    )
    controller.send :render, :file => template_file('edit'), :layout => true
  end
  
  def index(controller)
    controller.instance_variable_set(
      :@records, model_class.find(:all, :limit => 25, :order => 'id desc')
    )
    controller.instance_variable_set :@admin_assistant, self
    controller.send :render, :file => template_file('index'), :layout => true
  end
  
  def model_class_name
    @model_class.name.gsub(/([A-Z])/, ' \1')[1..-1].downcase
  end
  
  def model_class_symbol
    model_class.name.underscore.to_sym
  end
  
  def new(controller)
    controller.instance_variable_set :@admin_assistant, self
    controller.instance_variable_set(:@record, model_class.new)
    controller.send :render, :file => template_file('new'), :layout => true
  end
  
  def new_page_title
    "New #{model_class_name}"
  end
  
  def template_file(action)
    "#{RAILS_ROOT}/vendor/plugins/admin_assistant/lib/views/#{action}.html.erb"
  end
  
  def update(controller)
    record = model_class.find controller.params[:id]
    record.attributes = controller.params[model_class_symbol]
    if record.save
      controller.send :redirect_to, :action => 'index'
    else
      controller.instance_variable_set :@admin_assistant, self
      controller.instance_variable_set :@record, record
      controller.send :render, :file => template_file('edit'), :layout => true
    end
  end
  
  def url_params(action)
    {:controller => @controller_class.controller_path, :action => action}
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
      self.admin_assistant = AdminAssistant.new(model_class, self)
    end
  end
end
