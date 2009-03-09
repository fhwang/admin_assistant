require 'admin_assistant/column'
require 'admin_assistant/helper'
require 'admin_assistant/index'
require 'admin_assistant/request'
require 'will_paginate'

class AdminAssistant
  attr_reader :custom_column_labels, :form_settings, :index_settings, 
              :model_class
  attr_accessor :actions
  
  def initialize(controller_class, model_class)
    @controller_class, @model_class = controller_class, model_class
    @actions = [:index, :create, :update, :delete]
    @form_settings = FormSettings.new self
    @index_settings = IndexSettings.new self
    @custom_column_labels = {}
  end
  
  def dispatch_to_request_method(request_method, controller)
    controller.instance_variable_set :@admin_assistant, self
    klass = Request.const_get request_method.to_s.capitalize
    @request = klass.new(self, controller)
    @request.call
    @request = nil
  end
  
  def method_missing(meth, *args)
    request_methods = [:create, :edit, :index, :new, :update]
    if request_methods.include?(meth) and args.size == 1
      dispatch_to_request_method meth, args.first
    else
      if meth.to_s =~ /(.*)\?/ && request_methods.include?($1.to_sym)
        @actions.include?($1.to_sym)
      elsif @request.respond_to?(meth)
        @request.send meth, *args
      else
        super
      end
    end
  end
    
  def model_class_name
    model_class.name.gsub(/([A-Z])/, ' \1')[1..-1].downcase
  end
  
  def url_params(a = action)
    {:controller => @controller_class.controller_path, :action => a}
  end
  
  class Builder
    attr_reader :admin_assistant
    
    def initialize(admin_assistant)
      @admin_assistant = admin_assistant
    end
    
    def actions(*a)
      @admin_assistant.actions = a
    end
    
    def label(column, label)
      @admin_assistant.custom_column_labels[column.to_s] = label
    end
      
    def form
      yield @admin_assistant.form_settings
    end
      
    def index
      yield @admin_assistant.index_settings
    end
  end
  
  module ControllerMethods
    def self.included(controller)
      controller.extend ControllerClassMethods
      controller.class_inheritable_accessor :admin_assistant
    end
  end
  
  module ControllerClassMethods
    def admin_assistant_for(model_class, &block)
      self.admin_assistant = AdminAssistant.new(self, model_class)
      builder = Builder.new self.admin_assistant
      if block
        block.call builder
      end
      self.helper AdminAssistant::Helper
      [:create, :edit, :index, :new, :update].each do |action|
        self.send(:define_method, action) do
          self.class.admin_assistant.send(action, self)
        end
      end
    end
  end
  
  class Settings
    attr_reader :column_names
    
    def initialize(admin_assistant)
      @admin_assistant = admin_assistant
    end
    
    def columns(*args)
      @column_names = args
    end
  end
  
  class FormSettings < Settings
    attr_reader :inputs, :submit_buttons
    
    def initialize(admin_assistant)
      super
      @inputs = {}
      @submit_buttons = []
      @read_only = []
    end
    
    def read_only(*args)
      if args.empty?
        @read_only
      else
        args.each do |arg| @read_only << arg.to_s; end
      end
    end
  end
  
  class IndexSettings < Settings
    attr_reader :actions, :sort_by
    
    def initialize(admin_assistant)
      super
      @actions = {}
      @sort_by = 'id desc'
      @boolean_labels = {}
    end
    
    def boolean_labels(*args)
      if args.size == 1
        args.first.each do |column_name, pairs|
          @boolean_labels[column_name.to_s] = pairs
        end
      else
        @boolean_labels
      end
    end
    
    def conditions(&block)
      block ? (@conditions = block) : @conditions
    end
    
    def sort_by(*sb)
      if sb.empty?
        @sort_by
      else
        @sort_by = sb
      end
    end
  end
end

ActionController::Base.send :include, AdminAssistant::ControllerMethods

FileUtils.copy(
  "#{File.dirname(__FILE__)}/stylesheets/admin_assistant.css",
  "#{RAILS_ROOT}/public/stylesheets/admin_assistant.css"
)
images_dir = "#{RAILS_ROOT}/public/images/admin_assistant"
FileUtils.mkdir(images_dir) unless File.exist?(images_dir)
FileUtils.cp_r(Dir.glob("#{File.dirname(__FILE__)}/images/*"), images_dir)
