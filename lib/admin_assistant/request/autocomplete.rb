class AdminAssistant
  module Request
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
        action =~ /autocomplete_(.*)/
        associated_class = Module.const_get $1.camelize
        target = AssociationTarget.new associated_class
        field = target.default_name_method
        associated_class.find(
          :all,
          :conditions => [
            "LOWER(#{field}) like ?",
            "%#{search_string.downcase unless search_string.nil?}%"
          ],
          :limit => 10, :order => "length(#{field}), lower(#{field})"
        )
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
  end
end
