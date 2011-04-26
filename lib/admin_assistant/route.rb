class AdminAssistant
  class Route
    attr_reader :admin_assistant
    
    def initialize(admin_assistant)
      @admin_assistant = admin_assistant
    end
    
    def add(binding)
      route_str = "resources(:#{resource})"
      unless autocomplete_actions.empty?
        route_str << " do "
        autocomplete_actions.each do |action|
          route_str << " get :#{action}, :on => :collection;"
        end
        route_str << " end "
      end
      if namespace
        route_str = "namespace(:#{namespace}) do " + route_str + " end"
      end
      eval(route_str, binding)
    end
    
    def autocomplete_actions
      admin_assistant.autocomplete_actions
    end
    
    def controller
      admin_assistant.controller_class
    end
    
    def namespace
      name = controller.name.gsub(/Controller$/, '').underscore
      if name =~ %r|(.*)/(.*)|
        $1.to_sym
      end
    end
    
    def resource
      name = controller.name.gsub(/Controller$/, '').underscore
      if name =~ %r|(.*)/(.*)|
        $2.to_sym
      else
        name.to_sym
      end
    end
  end
end


