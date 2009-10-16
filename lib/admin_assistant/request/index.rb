class AdminAssistant
  module Request
    class Index < Base
      def call
        index = AdminAssistant::Index.new(
          @admin_assistant, @controller.params, controller_methods
        )
        @controller.instance_variable_set :@index, index
        if @controller.respond_to?(:before_render_for_index)
          @controller.send :before_render_for_index
        end
        render_template_file
      end
      
      def columns
        @admin_assistant.index_settings.columns
      end
      
      def controller_methods
        c_methods = {}
        possible_methods = [
          :conditions_for_index, :extra_right_column_links_for_index
        ]
        possible_methods.each do |mname|
          if @controller.respond_to?(mname)
            c_methods[mname] = @controller.method mname
          end
        end
        c_methods
      end
    end
  end
end
