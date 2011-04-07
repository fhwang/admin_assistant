class AdminAssistant
  module Request
    class Autocomplete < Base
      def associated_class
        @associated_class ||= Module.const_get(
          underscored_assoc_class_name.camelize
        )
      end
      
      def call
        results = records.map { |record|
          {:id => record.id.to_s, :name => record.send(record_name_field)}
        }
        @controller.send(:render, :json => results.to_json)
      end
      
      def record_name_field
        AssociationTarget.new(associated_class).default_name_method
      end
      
      def records
        action =~ /autocomplete_(.*)/
        associated_class.find(
          :all,
          :conditions => [
            "LOWER(#{record_name_field}) like ?",
            "%#{search_string.downcase unless search_string.nil?}%"
          ],
          :limit => 10,
          :order => "length(#{record_name_field}), lower(#{record_name_field})"
        )
      end
      
      def search_string
        @controller.params['q']
      end
      
      def underscored_assoc_class_name
        action =~ /autocomplete_(.*)/
        $1
      end
    end
  end
end
