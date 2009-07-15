class AdminAssistant
  module Request
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
          render_template_file 'form'
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
