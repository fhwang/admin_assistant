require File.expand_path(
  File.dirname(__FILE__) + '/../vendor/ar_query/lib/ar_query'
)

class AdminAssistant
  attr_accessor :model_class
  
  def initialize(model_class)
    @model_class = model_class
  end
  
  def method_missing(meth, *args)
    request_methods = [:create, :edit, :index, :new, :search, :update]
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
    
    def search
      self.class.admin_assistant.search self
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
      
      def render_edit
        render_template_file(
          'form', :locals => {:action => 'update', :id => @record.id}
        )
      end

      def render_new
        render_template_file 'form', :locals => {:action => 'create'}
      end
      
      def render_template_file(template_name = action, options_plus = {})
        options = {:file => template_file(template_name), :layout => true}
        options = options.merge options_plus
        @controller.send(:render, options)
      end
    
      def template_file(template_name = action)
        "#{RAILS_ROOT}/vendor/plugins/admin_assistant/lib/views/#{template_name}.html.erb"
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
          render_new
        end
      end
    end
    
    class Edit < Base
      def call
        @record = model_class.find @controller.params[:id]
        @controller.instance_variable_set :@record, @record
        render_edit
      end
    end
    
    class Index < Base
      def call
        @controller.instance_variable_set(
          :@records, model_class.find(:all, :limit => 25, :order => 'id desc')
        )
        @controller.instance_variable_set(
          :@search, AdminAssistant::Search.new(model_class)
        )
        render_template_file
      end
    end
    
    class New < Base
      def call
        @controller.instance_variable_set :@record, model_class.new
        render_new
      end
    end
    
    class Search < Base
      def call
        search = AdminAssistant::Search.new(
          model_class, @controller.params[:search]
        )
        @controller.instance_variable_set(:@search, search)
        @controller.instance_variable_set(:@records, search.records)
        render_template_file 'index'
      end
    end
    
    class Update < Base
      def call
        @record = model_class.find @controller.params[:id]
        @record.attributes = @controller.params[model_class_symbol]
        if @record.save
          @controller.send :redirect_to, :action => 'index'
        else
          @controller.instance_variable_set :@record, @record
          render_edit
        end
      end
    end
  end
  
  class Search
    attr_accessor :terms
    
    def initialize(model_class, atts = {})
      @model_class = model_class
      atts.each do |k, v| self.send("#{k}=", v); end
    end
    
    def records
      unless @records
        searchable_columns = @model_class.columns.select { |column|
          [:string, :text].include?(column.type)
        }
        ar_query = ARQuery.new :boolean_join => :or
        searchable_columns.each do |column|
          ar_query.condition_sqls << "#{column.name} like ?"
          ar_query.bind_vars << "%#{terms}%"
        end
        @records = @model_class.find :all, :conditions => ar_query[:conditions]
      end
      @records
    end
  end
end
