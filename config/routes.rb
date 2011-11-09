# In development mode, we need to ensure that all controllers are loaded,
# because that's how AdminAssistant knows what routes to create
unless Rails.configuration.cache_classes
  controllers_path = "#{Rails.root}/app/controllers"
  AdminAssistant.all_files_under(controllers_path).each do |path|
    if path =~ /\.rb$/
      if File.readlines(path).any? { |line| line =~ /admin_assistant_for/ }
        require path
      end
    end
  end
end

Rails.application.routes.draw do
  AdminAssistant.routes.each do |route|
    route.add(binding)
  end
end

