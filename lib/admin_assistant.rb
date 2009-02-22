require 'admin_assistant/helper'
require 'admin_assistant/index'
require 'admin_assistant/request'

class AdminAssistant
  attr_reader :model_class, :params_filter_for_save, :request_configs
  attr_accessor :before_save

  def initialize(controller_class, model_class)
    @controller_class, @model_class = controller_class, model_class
    @params_filter_for_save = {}
    @request_configs = Hash.new { |h,k| h[k] = {} }
    @request_configs[:form][:inputs] = {}
  end
  
  def method_missing(meth, *args)
    request_methods = [:create, :edit, :index, :new, :update]
    if request_methods.include?(meth) and args.size == 1
      controller = args.first
      controller.instance_variable_set :@admin_assistant, self
      klass = Request.const_get meth.to_s.capitalize
      @request = klass.new(self, controller)
      @request.call
      @request = nil
    elsif @request.respond_to?(meth)
      @request.send meth, *args
    else
      super
    end
  end
    
  def model_class_name
    model_class.name.gsub(/([A-Z])/, ' \1')[1..-1].downcase
  end
  
  def url_params(a = action)
    {:controller => @controller_class.controller_path, :action => a}
  end
  
  class Column
    def label
      if name.to_s == 'id'
        'ID'
      else
        name.to_s.capitalize.gsub(/_/, ' ') 
      end
    end
  end
  
  class ActiveRecordColumn < Column
    def initialize(ar_column)
      @ar_column = ar_column
    end
    
    def name
      @ar_column.name
    end
    
    def type
      @ar_column.type
    end
  end
  
  class AdminAssistantColumn < Column
    attr_reader :name
    
    def initialize(name)
      @name = name
    end
    
    def html_for_form(form)
      form.text_field name
    end
  end
  
  class Builder
    attr_reader :admin_assistant
    
    def initialize(admin_assistant)
      @admin_assistant = admin_assistant
    end
      
    def before_save(&block)
      @admin_assistant.before_save = block
    end
    
    def form
      yield Form.new(self)
    end
      
    def index
      yield Index.new(self)
    end
    
    def method_missing(meth, *args, &block)
      if meth.to_s =~ /(.*)_for_save/
        admin_assistant.params_filter_for_save[$1.to_sym] = block
      else
        super
      end
    end
    
    class Form
      def initialize(builder); @builder = builder; end
        
      def columns(*columns)
        @builder.admin_assistant.request_configs[:form][:columns] = columns
      end
      
      def inputs
        @builder.admin_assistant.request_configs[:form][:inputs]
      end
    end
    
    class Index
      def initialize(builder); @builder = builder; end
      
      def columns(*columns)
        @builder.admin_assistant.request_configs[:index][:columns] = columns
      end
    end
  end
  
  module ControllerMethods
    def self.included(controller)
      controller.extend ControllerClassMethods
      controller.class_inheritable_accessor :admin_assistant
      controller.helper AdminAssistant::Helper
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
    def admin_assistant_for(model_class, &block)
      self.admin_assistant = AdminAssistant.new(self, model_class)
      builder = Builder.new self.admin_assistant
      if block
        block.call builder
      end
    end
  end
end
