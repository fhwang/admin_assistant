# In development mode, we need to ensure that all controllers are loaded,
# because that's how AdminAssistant knows what routes to create
unless Rails.configuration.cache_classes
  Find.find("#{Rails.root}/app/controllers") do |path|
    if path =~ /\.rb$/
      require path
    end
  end
end

Rails.application.routes.draw do
  AdminAssistant.routes.each do |route|
    route.add(binding)
  end
end

