$: << File.join(File.dirname(__FILE__), '../vendor/ar_query/lib')
require 'find'
require 'admin_assistant/column'
Find.find(File.dirname(__FILE__)) do |path|
  if path =~ %r|\.rb$| && path !~ %r|admin_assistant\.rb$| &&
     path !~ %r|admin_assistant/column\.rb$|
    require path
  end
end
require 'will_paginate'

class AdminAssistant
  cattr_accessor :request_start_time

  def self.profile(msg)
    if self.request_start_time
      Rails.logger.info "#{msg}: #{Time.now - self.request_start_time}"
    end
  end
  
  def self.template_file(template_name)
    "#{File.dirname(__FILE__)}/views/#{template_name}.html.erb"
  end

  attr_reader   :base_settings, :controller_class, :form_settings, 
                :index_settings, :model_class, :show_settings
  attr_accessor :actions, :custom_destroy, :default_search_matches_on
  attr_writer   :model_class_name
  
  def initialize(controller_class, model_class)
    @controller_class, @model_class = controller_class, model_class
    @model = Model.new model_class
    @actions = [:index, :create, :update, :show]
    @form_settings = FormSettings.new self
    @index_settings = IndexSettings.new self
    @show_settings = ShowSettings.new self
    @base_settings = BaseSettings.new self
    @default_search_matches_on = @model.searchable_columns.map &:name
  end
  
  def [](name)
    @base_settings[name]
  end
    
  def accumulate_columns(names)
    columns = @model.paperclip_attachments.map { |paperclip_attachment|
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
  
  def accumulate_belongs_to_columns(names)
    accumulate_columns(names).select { |column| column.is_a?(BelongsToColumn) }
  end
  
  def autocomplete_actions
    @autocomplete_actions ||= begin
      ac_actions = []
      if [:new, :create, :edit, :update].any? { |action|
        actions.include?(action)
      }
        defaults = @model.default_column_names
        accumulate_belongs_to_columns(defaults).each { |column|
          ac_actions << "autocomplete_#{column.name}".to_sym
        }
      end
      if actions.include?(:index)
        base_settings.all_polymorphic_types.each do |p_type|
          ac_actions << "autocomplete_#{p_type.name.underscore.downcase}".to_sym
        end
      end
      ac_actions.uniq
    end
    @autocomplete_actions
  end
  
  def column(name)
    if @model.file_columns.include?(name.to_s)
      FileColumnColumn.new name
    elsif @model.paperclip_attachments.include?(name)
      PaperclipColumn.new name
    elsif (belongs_to_assoc = @model.belongs_to_assoc(name) or
           belongs_to_assoc = @model.belongs_to_assoc_by_foreign_key(name))
      column_based_on_belongs_to_assoc name, belongs_to_assoc
    elsif belongs_to_assoc = @model.belongs_to_assoc_by_polymorphic_type(name)
      # skip it, actually
    elsif (ar_column = @model_class.columns_hash[name.to_s])
      ActiveRecordColumn.new ar_column
    else
      VirtualColumn.new name, @model_class, self
    end
  end
  
  def column_based_on_belongs_to_assoc(name, belongs_to_assoc)
    if belongs_to_assoc.options[:polymorphic]
     PolymorphicBelongsToColumn.new belongs_to_assoc
    else
      BelongsToColumn.new(
        belongs_to_assoc,
        :match_text_fields_in_search => 
            search_settings[name].match_text_fields_for_association?,
        :sort_by => index_settings[name].sort_by
      )
    end
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
  
  def crudful_request_methods
    [:create, :destroy, :edit, :index, :new, :update, :show]
  end
  
  def default_column_names
    @model.default_column_names
  end
  
  def dispatch_to_request_method(request_class, controller)
    controller.instance_variable_set :@admin_assistant, self
    @request = request_class.new(self, controller)
    @request.call
    @request = nil
  end
  
  def file_columns
    @model.file_columns
  end
  
  def method_missing(meth, *args)
    if crudful_request_methods.include?(meth) and args.size == 1
      self.class.request_start_time = Time.now if ENV['PROFILE_LOGGING']
      request_class = Request.const_get meth.to_s.capitalize
      dispatch_to_request_method request_class, args.first
    elsif autocomplete_actions && autocomplete_actions.include?(meth)
      dispatch_to_request_method Request::Autocomplete, args.first
    elsif meth.to_s =~ /(.*)\?/ && crudful_request_methods.include?($1.to_sym)
      supports_action? $1
    else
      super
    end
  end
    
  def model_class_name
    @model_class_name ||
        @model_class.name.gsub(/([A-Z])/, ' \1')[1..-1].downcase
  end
  
  def paperclip_attachments
    @model.paperclip_attachments
  end
  
  def search_settings
    @index_settings.search_settings
  end
  
  def supports_action?(action)
    @memoized_action_booleans ||= {}
    unless @memoized_action_booleans.has_key?(action)
      @memoized_action_booleans[action] = 
          @controller_class.public_instance_methods.include?(action)
    end
    @memoized_action_booleans[action]
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
      begin
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
      rescue ActiveRecord::StatementInvalid
        Rails.logger.info "Skipping admin_assistant_for for #{self.name} because the table doesn't exist in the DB. Hopefully that's because you're deploying with a migration."
      end
    end
  end
  
  class Model
    def initialize(ar_model)
      @ar_model = ar_model
    end
  
    def belongs_to_associations
      @ar_model.reflect_on_all_associations.select { |assoc|
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
    
    def default_column_names
      @ar_model.columns.reject { |ar_column|
        %w(id created_at updated_at).include?(ar_column.name)
      }.map { |ar_column| ar_column.name }
    end
    
    def accessors
      @ar_model.instance_methods.
          select { |m| m =~ /=$/ }.
          map { |m| m.gsub(/=/, '')}.
          select { |m| @ar_model.instance_methods.include?(m) }
    end
  
    def file_columns
      unless @file_columns
        @file_columns = []
        if @ar_model.respond_to?(:file_column)
          names_to_check = @ar_model.columns.map(&:name).concat(accessors).uniq
          @file_columns = names_to_check.select { |name|
            %w( relative_path dir relative_dir temp ).all? { |suffix|
              @ar_model.method_defined? "#{name}_#{suffix}".to_sym
            }
          }
        end
      end
      @file_columns
    end
    
    def paperclip_attachments
      pa = []
      if @ar_model.respond_to?(:attachment_definitions)
        if @ar_model.attachment_definitions
          pa = @ar_model.attachment_definitions.map { |name, definition|
            name
          }
        end
      end
      pa
    end
  
    def searchable_columns
      @ar_model.columns.select { |column|
        [:string, :text].include?(column.type)
      }
    end
  end
end

ActionController::Base.send :include, AdminAssistant::ControllerMethods

