class AdminAssistant
  module Request
    def self.dispatch(action_name, admin_assistant, controller)
      class_name = action_name.to_s.capitalize
      if [:create, :new].include?(action_name)
        if admin_assistant.form_settings.multi?
          class_name = "Multi#{class_name}"
        else
          class_name = "Single#{class_name}"
        end
      end
      const_get(class_name).new(admin_assistant, controller).call
    end
    
    class Base
      def initialize(admin_assistant, controller)
        @admin_assistant, @controller = admin_assistant, controller
        controller.instance_variable_set :@admin_assistant, admin_assistant
      end
  
      def action
        @controller.action_name
      end
      
      def after_template_file(template_name)
        File.join(
          Rails.root, 'app/views/', @controller.controller_path, 
          "_after_#{template_name}.html.erb"
        )
      end
      
      def before_template_file(template_name)
        File.join(
          Rails.root, 'app/views/', @controller.controller_path, 
          "_before_#{template_name}.html.erb"
        )
      end
      
      def model_class
        @admin_assistant.model_class
      end
    
      def model_class_symbol
        model_class.name.underscore.to_sym
      end
      
      def origin
        @controller.params[:origin] || @controller.request.referer ||
            @controller.url_for({:action => 'index'})
      end
      
      def render_single_form(record)
        @controller.instance_variable_set :@record, record
        @controller.instance_variable_set :@origin, origin
        render_template_file 'form'
      end
      
      def render_multi_form(records)
        @controller.instance_variable_set :@records, records
        @controller.instance_variable_set :@origin, origin
        render_template_file 'multi_form'
      end
      
      def render_template_file(template_name = action, opts_plus = {})
        html = ''
        html << render_to_string_if_exists(
          before_template_file(template_name), opts_plus
        )
        html << render_to_string(
          AdminAssistant.template_file(template_name), opts_plus
        )
        html << render_to_string_if_exists(
          after_template_file(template_name), opts_plus
        )
        render_as_text_opts = {:text => html, :layout => true}.merge(opts_plus)
        @controller.send :render, render_as_text_opts
      end
      
      def render_to_string(template_file, options_plus)
        after_template_opts = {
          :file => template_file, :layout => false
        }.merge options_plus
        @controller.send :render_to_string, after_template_opts
      end
      
      def render_to_string_if_exists(template_file, opts_plus)
        if File.exist?(template_file)
          render_to_string(template_file, opts_plus)
        else
          ''
        end
      end
    end
    
    class ParamsForSave < Hash
      attr_reader :errors
      
      def initialize(controller, record, record_params=nil)
        super()
        @controller, @record_params = controller, record_params
        @model_class_symbol = record.class.name.underscore.to_sym
        @record_params ||= @controller.params[@model_class_symbol]
        @model_methods = record.methods
        @model_columns = record.class.columns
        @errors = Errors.new
        build_from_split_params
        destroy_params.each do |k,v|
          apply_destroy_param k, v
        end
        build_from_whole_params
      end
      
      def apply_destroy_param(name, value)
        if whole_params[name].blank?
          self[name] = nil
          mname = "destroy_#{name}_in_attributes"
          if @controller.respond_to?(mname)
            @controller.send(mname, self)
          end
        end
      end
      
      def build_from_split_params
        bases = split_params.map { |k, v| k.gsub(split_param_regex, '') }.uniq
        bases.each do |b|
          h = {}
          from_form_method = "#{b}_from_form".to_sym
          if @controller.respond_to?(from_form_method)
            split_params.each { |k, v|
              if k =~ /#{b}#{split_param_regex.source}/
                h[$1] = split_params.delete(k)
              end
            }
            self[b] = @controller.send(from_form_method, h)
          elsif model_setter?(b)
            split_params.each { |k, v|
              if k =~ /#{b}#{split_param_regex.source}/
                h[k] = split_params.delete(k)
              end
            }
            self.merge! h
          end
        end
      end
      
      def build_from_whole_params
        whole_params.each do |k, v|
          from_form_method = "#{k}_from_form".to_sym
          if @controller.respond_to?(from_form_method)
            args = [v]
            if @controller.method(from_form_method).arity >= 2
              args << @record_params
            end
            args << @errors if @controller.method(from_form_method).arity >= 3
            self[k] = @controller.send(from_form_method, *args)
          elsif model_setter?(k)
            unless destroy_params[k] && v.blank?
              self[k] = value_from_param(k, v)
            end
          end
        end
      end
      
      def destroy_params
        dp = {}
        @record_params.each do |k,v|
          if k =~ %r|(.*)\(destroy\)|
            dp[$1] = v
          end
        end
        dp
      end
      
      def model_setter?(attr)
        @model_columns.any? { |mc| mc.name.to_s == attr } or
            @model_methods.include?("#{attr}=")
      end
      
      def split_param_key?(key)
        key =~ split_param_regex
      end
      
      def split_param_regex
        @split_param_regex ||= /\((.+i)\)$/
      end
      
      def split_params
        sp = {}
        @record_params.each do |k,v| sp[k] = v if split_param_key?(k); end
        sp
      end
      
      def value_from_param(name, str)
        column = @model_columns.detect { |c| c.name == name }
        if column && column.type == :boolean
          if str == '1'
            true
          elsif str == '0'
            false
          else
            nil
          end
        else
          str
        end
      end
      
      def whole_params
        wp = {}
        @record_params.each do |k,v|
          unless split_param_key?(k) || k =~ %r|(.*)\(destroy\)|
            wp[k] = v
          end
        end
        wp
      end
      
      class Error
        attr_reader :message
        
        def initialize(attribute, message, options)
          @attribute, @message, @options = attribute, message, options
        end
      end
      
      class Errors
        def initialize
          @errors = Hash.new { |h,k| h[k] = []}
        end
        
        def add(error_or_attr, message = nil, options = {})
          error, attribute = error_or_attr.is_a?(Error) ? [error_or_attr, error_or_attr.attribute] : [nil, error_or_attr]
          options[:message] = options.delete(:default) if options.has_key?(:default)
    
          @errors[attribute.to_s] << (error || Error.new(attribute, message, options))
        end
        
        def each
          @errors.each do |attr, ary|
            ary.each do |error|
              yield attr, error.message
            end
          end
        end
        
        def each_attribute
          @errors.keys.each do |key| yield key; end
        end
        
        def empty?
          @errors.empty?
        end
      end
    end
    
    class AbstractSaving
      attr_reader :record
      
      def initialize(record, controller)
        @record, @controller = record, controller
      end
      
      def params_for_save
        ParamsForSave.new(@controller, @record)
      end
      
      def record_and_associations_valid?
        if @controller.respond_to?(:before_validation)
          @controller.send(:before_validation, record)
        end
        params = params_for_save
        prepare_record_to_receive_invalid_association_assignments
        record.attributes = params
        record.valid?
        params.errors.each do |attr, msg| record.errors.add(attr, msg); end
        if @controller.respond_to?(:validate)
          @controller.send(:validate, record)
        end
        record.errors.empty?
      end
      
      def redirect_after_save
        url_params = if @controller.respond_to?(:destination_after_save)
          @controller.send(
            :destination_after_save, @record, @controller.params
          )
        end
        url_params ||= @controller.params[:origin]
        url_params ||= {:action => 'index'}
        @controller.send :redirect_to, url_params
      end
      
      def save
        if @controller.respond_to?(:before_save)
          @controller.send(:before_save, record)
        end
        result = record.save
        if result && @controller.respond_to?(:after_save)
          @controller.send(:after_save, record)
        end
        result
      end
    end
  end
end
