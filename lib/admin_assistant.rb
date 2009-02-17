class AdminAssistant
  attr_accessor :model_class
  
  def initialize(model_class)
    @model_class = model_class
  end
  
  def index(controller)
    controller.instance_variable_set(
      :@records, model_class.find(:all, :limit => 25, :order => 'id desc')
    )
    controller.send :render, :template => template('index')
  end
  
  def template(action)
    "../../vendor/plugins/admin_assistant/lib/views/#{action}.html.erb"
  end

  module ControllerMethods
    def self.included(controller)
      controller.extend ControllerClassMethods
      controller.cattr_accessor :admin_assistant
    end
  
    def index
      self.class.admin_assistant.index self
    end
  end
  
  module ControllerClassMethods
    def admin_assistant_for(model_class)
      self.admin_assistant = AdminAssistant.new(model_class)
    end
  end
end
