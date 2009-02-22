class AdminAssistant
  module Helper
    def html_for_index(column, record)
      html_for_index_method = "#{column.name}_html_for_index"
      if respond_to?(html_for_index_method)
        self.send html_for_index_method, record
      else
        h(record.send(column.name))
      end
    end
    
    def html_for_form(column, record, form)
      html_method = "#{column.name}_html_for_form"
      if respond_to?(html_method)
        self.send(html_method, record)
      else
        column.html_for_form(form)
      end
    end
  end
end
