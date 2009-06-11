class AdminAssistant
  module Helper
    def admin_assistant_includes(opts = {})
      theme = opts[:theme] || 'default'
      stylesheet_link_tag("admin_assistant_#{theme}") +
          javascript_include_tag('admin_assistant')
    end
  end
end
