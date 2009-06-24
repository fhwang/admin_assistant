class AdminAssistant
  module Request
    class Base
      def initialize(admin_assistant, controller)
        @admin_assistant, @controller = admin_assistant, controller
      end
  
      def action
        @controller.action_name
      end
      
      def after_form_html_template
        File.join(
          RAILS_ROOT, 'app/views/', @controller.controller_path, 
          '_after_form.html.erb'
        )
      end
      
      def after_form_html_template_exists?
        File.exist? after_form_html_template
      end
      
      def model_class
        @admin_assistant.model_class
      end
    
      def model_class_symbol
        model_class.name.underscore.to_sym
      end
      
      def params_for_save
        params = {}
        split_params = {}
        whole_params = {}
        @controller.params[model_class_symbol].each do |k, v|
          k =~ /\([0-9]+i\)$/ ? (split_params[k] = v) : (whole_params[k] = v)
        end
        bases = split_params.map{ |k, v| k.gsub(/\([0-9]+i\)$/, '') }.uniq
        bases.each do |b|
          h = {}
          split_params.each{ |k, v| h[k] = split_params.delete(k) if k =~ /#{b}\([0-9]+i\)$/ }
          from_form_method = "#{b}_from_form".to_sym
          if @controller.respond_to?(from_form_method)
            params[b] = @controller.send(from_form_method, h)
          elsif @record.respond_to?("#{b}=")
            params.merge! h
          end
        end
        whole_params.each do |k, v|
          if k =~ %r|(.*)\(destroy\)|
            params[$1] = nil
          else
            from_form_method = "#{k}_from_form".to_sym
            if @controller.respond_to?(from_form_method)
              params[k] = @controller.send(from_form_method, v)
            elsif @record.respond_to?("#{k}=")
              params[k] = v
            end
          end
        end
        params
      end
      
      def redirect_after_save
        url_params = if @controller.respond_to?(:destination_after_save)
          @controller.send(
            :destination_after_save, @record, @controller.params
          )
        end
        url_params ||= {:action => 'index'}
        @controller.send :redirect_to, url_params
      end
      
      def render_after_form
        @controller.send(
          :render_to_string,
          :file => after_form_html_template, :layout => false
        )
      end
      
      def render_form
        html = @controller.send(
          :render_to_string,
          :file => AdminAssistant.template_file('form'), :layout => false
        )
        html << render_after_form if after_form_html_template_exists?
        @controller.send :render, :text => html, :layout => true
      end
      
      def render_template_file(template_name = action, options_plus = {})
        options = {
          :file => AdminAssistant.template_file(template_name), :layout => true
        }
        options = options.merge options_plus
        @controller.send(:render, options)
      end
      
      def save
        if @controller.respond_to?(:before_save)
          @controller.send(:before_save, @record)
        end
        result = @record.save
        if @controller.respond_to?(:after_save)
          @controller.send(:after_save, @record)
        end
        result
      end
    end
    
    class Autocomplete < Base
      def call
        action =~ /autocomplete_(.*)/
        column = @admin_assistant.column $1
        search_string = @controller.params["#{$1}_autocomplete_input"]
        opts = {
          :conditions => [
            "LOWER(#{column.default_name_method}) like ?",
            "%#{search_string.downcase unless search_string.nil?}%"
          ],
          :limit => 10
        }
        records = column.associated_class.find :all, opts
        render_template_file(
          'autocomplete', :layout => false,
          :locals => {:records => records, :prefix => $1, :column => column}
        )
      end
    end
    
    class Create < Base
      def call
        @record = model_class.new
        @record.attributes = params_for_save
        if save
          redirect_after_save
        else
          @controller.instance_variable_set :@record, @record
          render_form
        end
      end
      
      def save
        if @controller.respond_to?(:before_create)
          @controller.send(:before_create, @record)
        end
        result = super
        if @controller.respond_to?(:after_create)
          @controller.send(:after_create, @record)
        end
        result
      end
    end
    
    class Destroy < Base
      def call
        @record = model_class.find @controller.params[:id]
        @record.destroy
        @controller.send :render, :text => ''
      end
    end
    
    class Edit < Base
      def call
        @record = model_class.find @controller.params[:id]
        @controller.instance_variable_set :@record, @record
        render_form
      end
    end
    
    class Index < Base
      def call
        args = [@admin_assistant, @controller.params]
        if @controller.respond_to?(:conditions_for_index)
          args << @controller.send(:conditions_for_index)
        end
        index = AdminAssistant::Index.new *args
        @controller.instance_variable_set :@index, index
        render_template_file
      end
      
      def columns
        @admin_assistant.index_settings.columns
      end
    end
    
    class New < Base
      def call
        @record = model_class.new
        @admin_assistant.form_settings.columns_for_new.each do |column|
          if block = @admin_assistant.form_settings[column].default
            @record.send("#{column}=", block.call)
          end
        end
        if @controller.params[model_class_symbol]
          @record.attributes = params_for_save
        end
        @controller.instance_variable_set :@record, @record
        render_form
      end
    end
    
    class Show < Base
      def call
        @record = model_class.find @controller.params[:id]
        @controller.instance_variable_set :@record, @record
        @controller.send(
          :render,
          :file => AdminAssistant.template_file('show'), :layout => true
        )
      end
    end
    
    class Update < Base
      def call
        @record = model_class.find @controller.params[:id]
        @record.attributes = params_for_save
        if save
          if from = @controller.params[:from]
            from =~ /#{model_class.name.underscore}_\d+_(.*)/
            field_name = $1
            index = AdminAssistant::Index.new @admin_assistant
            erb = <<-ERB
              <%= index.view(self).columns.detect { |c| c.name == field_name }.
                        ajax_toggle_inner_html(record) %>
            ERB
            @controller.send(
              :render,
              :inline => erb,
              :locals => {
                :index => index, :field_name => field_name, :record => @record
              }
            )
          else
            redirect_after_save
          end
        else
          @controller.instance_variable_set :@record, @record
          render_form
        end
      end
      
      def save
        if @controller.respond_to?(:before_update)
          @controller.send(:before_update, @record)
        end
        super
      end
    end
  end
end
