require File.expand_path(
  File.dirname(__FILE__) + '/../vendor/ar_query/lib/ar_query'
)
require 'admin_assistant/request'

class AdminAssistant
  attr_reader :model_class, :params_filter_for_save, :request_configs

  def initialize(controller_class, model_class)
    @controller_class, @model_class = controller_class, model_class
    @params_filter_for_save = {}
    @request_configs = Hash.new { |h,k| h[k] = {} }
  end
  
  def method_missing(meth, *args)
    request_methods = [:create, :edit, :index, :new, :update]
    if request_methods.include?(meth) and args.size == 1
      klass = Request.const_get meth.to_s.capitalize
      @request = klass.new(self, args[0])
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
    def pretty_name
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
    
    def html_for_form(form)
      case type
        when :text
          form.text_area name
        else
          form.text_field name
        end
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
    
    def initialize(admin_assistant); @admin_assistant = admin_assistant; end
    
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
  
  class Index
    def initialize(model_class, url_params = {})
      @model_class = model_class
      @url_params = url_params
    end
    
    def next_sort_params(column_name)
      next_sort_order = 'asc'
      if @url_params[:sort] == column_name
        if sort_order == 'asc'
          next_sort_order = 'desc'
        else
          column_name = nil
          next_sort_order = nil
        end
      end
      {:sort => column_name, :sort_order => next_sort_order}
    end
    
    def records
      unless @records
        order = 'id desc'
        if @url_params[:sort]
          order = "#{@url_params[:sort] } #{sort_order}"
        end
        ar_query = ARQuery.new(:order => order, :limit => 25)
        ar_query.boolean_join = :or
        if search_terms
          searchable_columns = @model_class.columns.select { |column|
            [:string, :text].include?(column.type)
          }
          searchable_columns.each do |column|
            ar_query.condition_sqls << "#{column.name} like ?"
            ar_query.bind_vars << "%#{search_terms}%"
          end
        end
        @records = @model_class.find :all, ar_query
      end
      @records
    end
    
    def search_terms
      @url_params['search']
    end
    
    def sort_order
      @url_params[:sort_order] || 'asc'
    end
  end
end
