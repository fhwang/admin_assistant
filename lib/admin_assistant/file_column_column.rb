class AdminAssistant
  class FileColumnColumn < Column
    attr_reader :name
    
    def initialize(name)
      @name = name.to_s
    end
    
    def contains?(column_name)
      column_name.to_s == @name
    end

    class View < AdminAssistant::Column::View
      def file_exists?(record)
        if @file_exists_method
          @file_exists_method.call record
        else
          !source_for_image_tag(record).nil?
        end
      end
      
      def image_html(record)
        @action_view.image_tag(
          source_for_image_tag(record), :size => @image_size
        )
      end
      
      def source_for_image_tag(record)
        if @file_url_method
          @file_url_method.call record
        else
          @action_view.instance_variable_set :@record, record
          @action_view.url_for_file_column 'record', @column.name
        end
      end
    end
    
    class FormView < View
      include AdminAssistant::Column::FormViewMethods
      
      def default_html(form)
        if file_exists?(form.object)
          check_box_tag = @action_view.check_box_tag(
            "#{form.object.class.name.underscore}[#{name}(destroy)]"
          )
          <<-HTML
          <p>Current image:<br />#{image_html(form.object)}</p>
          <p>Remove: #{check_box_tag}</p>
          <p>Update: #{form.file_field(name)}</p>
          HTML
        else
          "<p>Add: #{form.file_field(name)}</p>"
        end
      end
    end

    class IndexView < View
      include AdminAssistant::Column::IndexViewMethods
      
      def html(record)
        image_html(record) if file_exists?(record)
      end
    end
    
    class ShowView < View
      include AdminAssistant::Column::ShowViewMethods
      
      def html(record)
        image_html(record) if file_exists?(record)
      end
    end
  end
end
