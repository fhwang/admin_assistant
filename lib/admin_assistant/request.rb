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
        ParamsForSave.new(@controller, @record, model_class_symbol)
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
      def associated_class
        @associated_class ||= Module.const_get(
          underscored_assoc_class_name.camelize
        )
      end
      
      def call
        render_template_file(
          'autocomplete', :layout => false,
          :locals => {
            :records => records, :prefix => underscored_assoc_class_name,
            :associated_class => associated_class
          }
        )
      end
      
      def records
        target = AssociationTarget.new associated_class
        opts = {
          :conditions => [
            "LOWER(#{target.default_name_method}) like ?",
            "%#{search_string.downcase unless search_string.nil?}%"
          ],
          :limit => 10
        }
        associated_class.find :all, opts
      end
      
      def search_string
        @controller.params[
          "#{underscored_assoc_class_name}_autocomplete_input"
        ]
      end
      
      def underscored_assoc_class_name
        action =~ /autocomplete_(.*)/
        $1
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
        if @admin_assistant.custom_destroy
          @admin_assistant.custom_destroy.call @record
        else
          @record.destroy
        end
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
        controller_methods = {}
        possible_methods = [
          :conditions_for_index, :extra_right_column_links_for_index
        ]
        possible_methods.each do |mname|
          if @controller.respond_to?(mname)
            controller_methods[mname] = @controller.method mname
          end
        end
        index = AdminAssistant::Index.new(
          @admin_assistant, @controller.params, controller_methods
        )
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
            @record.send("#{column}=", block.call(@controller))
          end
        end
        if @controller.params[model_class_symbol]
          @record.attributes = params_for_save
        end
        @controller.instance_variable_set :@record, @record
        render_form
      end
    end
    
    class ParamsForSave < Hash
      def initialize(controller, record, model_class_symbol)
        super()
        @controller, @record, @model_class_symbol =
            controller, record, model_class_symbol
        build_from_split_params
        destroy_params.each do |k,v|
          if whole_params[k].blank?
            self[k] = nil
            mname = "destroy_#{k}_in_attributes"
            if controller.respond_to?(mname)
              controller.send(mname, self)
            end
          end
        end
        build_from_whole_params
      end
      
      def build_from_split_params
        bases = split_params.map { |k, v| k.gsub(/\([0-9]+i\)$/, '') }.uniq
        bases.each do |b|
          h = {}
          split_params.each { |k, v|
            h[k] = split_params.delete(k) if k =~ /#{b}\([0-9]+i\)$/
          }
          from_form_method = "#{b}_from_form".to_sym
          if @controller.respond_to?(from_form_method)
            self[b] = @controller.send(from_form_method, h)
          elsif @record.respond_to?("#{b}=")
            self.merge! h
          end
        end
      end
      
      def build_from_whole_params
        whole_params.each do |k, v|
          from_form_method = "#{k}_from_form".to_sym
          if @controller.respond_to?(from_form_method)
            self[k] = @controller.send(from_form_method, v)
          elsif @record.respond_to?("#{k}=")
            unless destroy_params[k] && v.blank?
              self[k] = v
            end
          end
        end
      end
      
      def destroy_params
        dp = {}
        @controller.params[@model_class_symbol].each do |k,v|
          if k =~ %r|(.*)\(destroy\)|
            dp[$1] = v
          end
        end
        dp
      end
      
      def split_params
        sp = {}
        @controller.params[@model_class_symbol].each do |k,v|
          sp[k] = v if k =~ /\([0-9]+i\)$/
        end
        sp
      end
      
      def whole_params
        wp = {}
        @controller.params[@model_class_symbol].each do |k,v|
          unless k =~ /\([0-9]+i\)$/ || k =~ %r|(.*)\(destroy\)|
            wp[k] = v
          end
        end
        wp
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
          if @controller.params[:from]
            render_response_to_ajax_toggle
          else
            redirect_after_save
          end
        else
          @controller.instance_variable_set :@record, @record
          render_form
        end
      end
      
      def render_response_to_ajax_toggle
        @controller.params[:from] =~ /#{model_class.name.underscore}_\d+_(.*)/
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
