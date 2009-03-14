class AdminAssistant
  module Helper
    def admin_assistant_includes
      stylesheet_link_tag 'admin_assistant'
    end
    
    def controller_css_class
      controller.controller_path.gsub(%r|/|, '_')
    end
  end
end
