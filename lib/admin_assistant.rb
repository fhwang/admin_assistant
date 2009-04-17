$: << File.join(File.dirname(__FILE__), '../vendor/ar_query/lib')
require 'admin_assistant/builder'
require 'admin_assistant/column'
require 'admin_assistant/form_view'
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
    @actions = [:index, :create, :update]
    @form_settings = FormSettings.new self
    @index_settings = IndexSettings.new self
    @custom_column_labels = {}
  end
  
  def belongs_to_assoc(name)
    model_class.reflect_on_all_associations.detect { |assoc|
      assoc.macro == :belongs_to && assoc.name.to_s == name.to_s
    }
  end
  
  def column(name)
    column = if file_columns.include?(name)
      FileColumnColumn.new name
    elsif (ar_column = model_class.columns_hash[name.to_s])
      ActiveRecordColumn.new(ar_column)
    elsif belongs_to_assoc = belongs_to_assoc(name)
      BelongsToColumn.new(belongs_to_assoc)
    else
      AdminAssistantColumn.new(name)
    end
    if column && (custom = custom_column_labels[name.to_s])
      column.custom_label = custom
    end
    column
  end
  
  def column_name_or_assoc_name(name)
    result = name
    ar_column = model_class.columns_hash[name.to_s]
    if ar_column
      associations = model_class.reflect_on_all_associations
      if belongs_to_assoc = associations.detect { |assoc|
        assoc.macro == :belongs_to && assoc.association_foreign_key == name
      }
        result = belongs_to_assoc.name.to_s
      end
    end
    result
  end
    
  def columns(names)
    columns = paperclip_attachments.map { |paperclip_attachment|
      PaperclipColumn.new paperclip_attachment
    }
    names.each do |column_name|
      unless columns.any? { |column| column.contains?(column_name) }
        column = column column_name
        columns << column if column
      end
    end
    columns
  end
  
  def controller_actions
    c_actions = actions.clone
    c_actions << :new if c_actions.include?(:create)
    c_actions << :edit if c_actions.include?(:update)
    c_actions
  end
    
  def controller_css_class(controller)
    controller.controller_path.gsub(%r|/|, '_')
  end
  
  def dispatch_to_request_method(request_method, controller)
    controller.instance_variable_set :@admin_assistant, self
    klass = Request.const_get request_method.to_s.capitalize
    @request = klass.new(self, controller)
    @request.call
    @request = nil
  end
  
  def file_columns
    fc = []
    if model_class.respond_to?(:file_column)
      model_class.columns.each do |column|
        suffixes = %w( relative_path dir relative_dir temp )
        if suffixes.all? { |suffix|
          model_class.method_defined? "#{column.name}_#{suffix}".to_sym
        }
          fc << column.name
        end
      end
    end
    fc
  end
  
  def method_missing(meth, *args)
    request_methods = [:create, :destroy, :edit, :index, :new, :update]
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
    
  def paperclip_attachments
    pa = []
    if model_class.respond_to?(:attachment_definitions)
      if model_class.attachment_definitions
        pa = model_class.attachment_definitions.map { |name, definition|
          name
        }
      end
    end
    pa
  end
  
  def profile(msg)
    if @request_start_time
      puts "#{msg}: #{Time.now - @request_start_time}"
    end
  end
  
  def search_settings
    index_settings.search_settings
  end
  
  def url_params(a = action)
    {:controller => @controller_class.controller_path, :action => a}
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
      self.admin_assistant.controller_actions.each do |action|
        self.send(:define_method, action) do
          self.class.admin_assistant.send(action, self)
        end
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
