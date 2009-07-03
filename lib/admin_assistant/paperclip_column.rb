class AdminAssistant
  class PaperclipColumn < Column
    attr_reader :name
    
    def initialize(name)
      @name = name.to_s
    end
    
    def contains?(column_name)
      column_name.to_s == @name ||
      column_name.to_s =~
          /^#{@name}_(file_name|content_type|file_size|updated_at)$/
    end
    
    class View < AdminAssistant::Column::View
      def image_html(record)
        @action_view.image_tag record.send(@column.name).url
      end
    end
    
    class FormView < View
      include AdminAssistant::Column::FormViewMethods
      
      def html(form)
        form.file_field name
      end
    end

    class IndexView < View
      include AdminAssistant::Column::IndexViewMethods
      
      def html(record)
        image_html record
      end
    end
    
    class SearchView < View
      include AdminAssistant::Column::SearchViewMethods
    end
    
    class ShowView < View
      include AdminAssistant::Column::ShowViewMethods
      
      def html(record)
        image_html record
      end
    end
  end
end
