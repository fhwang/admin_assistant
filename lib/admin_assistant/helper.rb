class AdminAssistant
  module Helper
    def admin_assistant_includes
      stylesheet_link_tag('admin_assistant') +
          javascript_include_tag('admin_assistant')
    end
  end
end
