$: << File.join(File.dirname(__FILE__), '../vendor/ar_query/lib')
require 'dynamic_form'
require 'will_paginate'

require 'find'
files = %w(
  column virtual_column active_record_column association_target
  belongs_to_column builder default_search_column form_view has_many_column 
  helper index model paperclip_column polymorphic_belongs_to_column 
  request/base request/autocomplete request/create request/destroy request/edit
  request/index request/new request/show request/update route search show_view
)
files.each do |file|
  require "#{File.dirname(__FILE__)}/admin_assistant/#{file}"
end

class AdminAssistant
  cattr_accessor :default_inputs, :request_start_time, :routes
  self.default_inputs = {}
  self.routes = []
  
  # From http://stackoverflow.com/questions/3974087/how-to-make-rubys-find-find-follow-symlinks
  def self.all_files_under(*paths)
    paths.flatten!
    paths.map! { |p| Pathname.new(p) }
    files = paths.select { |p| p.file? }
    (paths - files).each do |dir|
      files << all_files_under(dir.children)
    end
    files.flatten.map(&:to_s)
  end
  
  def self.app_uses_sprockets?
    # For now, we assume you're using Sprockets if app/assets exists.
    File.exist?("#{Rails.root}/app/assets")
  end

  def self.profile(msg)
    if self.request_start_time
      Rails.logger.info "#{msg}: #{Time.now - self.request_start_time}"
    end
  end
  
  def self.template_file(template_name)
    "#{File.dirname(__FILE__)}/views/#{template_name}.html.erb"
  end
  
  attr_reader   :added_default_search_matches, :base_settings,
                :controller_class, :form_settings, :index_settings,
                :model_class, :show_settings
  attr_accessor :actions, :custom_destroy
  attr_writer   :default_search_matches_on, :model_class_name
  
  def initialize(controller_class, model_class)
    @controller_class, @model_class = controller_class, model_class
    @model = Model.new model_class
    @actions = [:index, :create, :update, :show]
    @form_settings = FormSettings.new self
    @index_settings = IndexSettings.new self
    @show_settings = ShowSettings.new self
    @base_settings = BaseSettings.new self
    @added_default_search_matches = []
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
        @model.belongs_to_associations.each do |assoc|
          ac_actions << "autocomplete_#{assoc.name}".to_sym
        end
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
    if @model.paperclip_attachments.include?(name)
      PaperclipColumn.new name
    elsif (belongs_to_assoc = @model.belongs_to_assoc(name) or
           belongs_to_assoc = @model.belongs_to_assoc_by_foreign_key(name))
      column_based_on_belongs_to_assoc name, belongs_to_assoc
    elsif belongs_to_assoc = @model.belongs_to_assoc_by_polymorphic_type(name)
      # skip it, actually
    elsif (ar_column = @model_class.columns_hash[name.to_s])
      ActiveRecordColumn.new ar_column
    elsif has_many_assoc = @model.has_many_assoc(name)
      HasManyColumn.new(
        has_many_assoc,
        :match_text_fields_in_search => 
            search_settings[name].match_text_fields_for_association?
      )
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

  def default_search_matches_on
    if @default_search_matches_on
      @default_search_matches_on
    else
      @model.searchable_columns.map(&:name).
             concat(added_default_search_matches)
    end
  end
  
  def method_missing(meth, *args)
    if crudful_request_methods.include?(meth) and args.size == 1
      self.class.request_start_time = Time.now if ENV['PROFILE_LOGGING']
      Request.dispatch meth, self, args.first
    elsif autocomplete_actions && autocomplete_actions.include?(meth)
      Request.dispatch :autocomplete, self, args.first
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
          @controller_class.public_instance_methods.any? { |meth|
            meth.to_sym == action.to_sym
          } 
    end
    @memoized_action_booleans[action]
  end
  
  def url_params(a = action)
    {:controller => @controller_class.controller_path, :action => a}
  end
  
  module ControllerMethods
    def self.included(controller)
      controller.extend ControllerClassMethods
      controller.class_attribute :admin_assistant
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
      AdminAssistant.routes << Route.new(self.admin_assistant)
    end
  end

  class Engine < ::Rails::Engine
  end
end
  
ActionController::Base.send :include, AdminAssistant::ControllerMethods

