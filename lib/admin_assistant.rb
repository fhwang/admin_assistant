$: << File.join(File.dirname(__FILE__), '../vendor/ar_query/lib')
require 'admin_assistant/builder'
require 'admin_assistant/column'
require 'admin_assistant/column/view'
require 'admin_assistant/form_view'
require 'admin_assistant/helper'
require 'admin_assistant/index'
require 'admin_assistant/request'
require 'admin_assistant/search'
require 'will_paginate'

class AdminAssistant
  attr_reader   :base_settings, :form_settings, :index_settings,  :model_class,
                :show_settings
  attr_accessor :actions
  attr_writer   :model_class_name
  
  def self.searchable_columns(model_class)
    model_class.columns.select { |column|
      [:string, :text].include?(column.type)
    }
  end

  def self.template_file(template_name)
    "#{File.dirname(__FILE__)}/views/#{template_name}.html.erb"
  end

  def initialize(controller_class, model_class)
    @controller_class, @model_class = controller_class, model_class
    @actions = [:index, :create, :update, :show]
    @form_settings = FormSettings.new self
    @index_settings = IndexSettings.new self
    @show_settings = ShowSettings.new self
    @base_settings = BaseSettings.new self
  end
  
  def [](name)
    @base_settings[name]
  end
    
  def accumulate_columns(names)
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
  
  def autocomplete_actions
    actions_hash = {}
    if [:new, :create, :edit, :update].any? { |action|
      actions.include?(action)
    }
      column_names = model_class.columns.reject { |ar_column|
        %w(id created_at updated_at).include?(ar_column.name)
      }.map { |ar_column| ar_column.name }
      accumulate_columns(column_names).select { |column|
        column.is_a?(BelongsToColumn)
      }.each { |column|
        actions_hash["autocomplete_#{column.name}".to_sym] = true
      }
    end
    if actions.include?(:index)
      all_polymorphic_types = 
          base_settings.column_configs.values.
                                       map(&:polymorphic_types).
                                       flatten.
                                       compact
      all_polymorphic_types.each do |p_type|
        action_name = "autocomplete_#{p_type.name.underscore.downcase}".to_sym
        actions_hash[action_name] = true
      end
    end
    actions_hash.keys
  end
  
  def belongs_to_associations
    @model_class.reflect_on_all_associations.select { |assoc|
      assoc.macro == :belongs_to
    }
  end
  
  def belongs_to_assoc(association_name)
    belongs_to_associations.detect { |assoc|
      assoc.name.to_s == association_name.to_s
    }
  end
  
  def belongs_to_assoc_by_foreign_key(foreign_key)
    belongs_to_associations.detect { |assoc|
      assoc.association_foreign_key == foreign_key
    }
  end
  
  def belongs_to_assoc_by_polymorphic_type(name)
    if name =~ /^(.*)_type/
      belongs_to_associations.detect { |assoc|
        assoc.options[:polymorphic] && $1 == assoc.name.to_s
      }
    end
  end
  
  def column(name)
    column = if file_columns.include?(name.to_s)
      FileColumnColumn.new name
    elsif paperclip_attachments.include?(name)
      PaperclipColumn.new name
    elsif (belongs_to_assoc = belongs_to_assoc(name) or
           belongs_to_assoc = belongs_to_assoc_by_foreign_key(name))
      if belongs_to_assoc.options[:polymorphic]
        PolymorphicBelongsToColumn.new belongs_to_assoc
      else
        BelongsToColumn.new(
          belongs_to_assoc,
          :match_text_fields_in_search => 
              search_settings[name].match_text_fields_for_association?
        )
      end
    elsif belongs_to_assoc = belongs_to_assoc_by_polymorphic_type(name)
      # skip it, actually
    elsif (ar_column = @model_class.columns_hash[name.to_s])
      ActiveRecordColumn.new ar_column
    else
      VirtualColumn.new name, @model_class
    end
    column
  end
  
  def controller_actions
    c_actions = actions.clone
    c_actions << :new if c_actions.include?(:create)
    c_actions << :edit if c_actions.include?(:update)
    c_actions.concat(autocomplete_actions) if autocomplete_actions
    c_actions
  end
    
  def controller_css_class(controller)
    controller.controller_path.gsub(%r|/|, '_')
  end
  
  def dispatch_to_request_method(request_class, controller)
    controller.instance_variable_set :@admin_assistant, self
    @request = request_class.new(self, controller)
    @request.call
    @request = nil
  end
  
  def file_columns
    unless @file_columns
      @file_columns = []
      if @model_class.respond_to?(:file_column)
        names_to_check = @model_class.columns.map &:name
        names_to_check.concat(
          @model_class.instance_methods.
              select { |m| m =~ /=$/ }.
              map { |m| m.gsub(/=/, '')}.
              select { |m| @model_class.instance_methods.include?(m) }
        )
        names_to_check.uniq.each do |name|
          suffixes = %w( relative_path dir relative_dir temp )
          if suffixes.all? { |suffix|
            @model_class.method_defined? "#{name}_#{suffix}".to_sym
          }
            @file_columns << name
          end
        end
      end
    end
    @file_columns
  end
  
  def method_missing(meth, *args)
    request_methods = [:create, :destroy, :edit, :index, :new, :update, :show]
    if request_methods.include?(meth) and args.size == 1
      request_class = Request.const_get meth.to_s.capitalize
      dispatch_to_request_method request_class, args.first
    elsif autocomplete_actions && autocomplete_actions.include?(meth)
      dispatch_to_request_method Request::Autocomplete, args.first
    else
      if meth.to_s =~ /(.*)\?/ && request_methods.include?($1.to_sym)
        @controller_class.public_instance_methods.include?($1)
      elsif @request.respond_to?(meth)
        @request.send meth, *args
      else
        super
      end
    end
  end
    
  def model_class_name
    @model_class_name ||
        @model_class.name.gsub(/([A-Z])/, ' \1')[1..-1].downcase
  end
    
  def paperclip_attachments
    pa = []
    if @model_class.respond_to?(:attachment_definitions)
      if @model_class.attachment_definitions
        pa = @model_class.attachment_definitions.map { |name, definition|
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
    @index_settings.search_settings
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

Dir.entries("#{File.dirname(__FILE__)}/stylesheets").each do |entry|
  if entry =~ /css$/
    FileUtils.copy(
      "#{File.dirname(__FILE__)}/stylesheets/#{entry}",
      "#{RAILS_ROOT}/public/stylesheets/#{entry}"
    )
  end
end
FileUtils.copy(
  "#{File.dirname(__FILE__)}/javascripts/admin_assistant.js",
  "#{RAILS_ROOT}/public/javascripts/admin_assistant.js"
)
images_dir = "#{RAILS_ROOT}/public/images/admin_assistant"
FileUtils.mkdir(images_dir) unless File.exist?(images_dir)
FileUtils.cp_r(Dir.glob("#{File.dirname(__FILE__)}/images/*"), images_dir)
