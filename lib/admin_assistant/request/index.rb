class AdminAssistant
  module Request
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
  end
end
