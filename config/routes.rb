Rails.application.routes.draw do
  AdminAssistant.routes.each do |route|
    route.add(binding)
  end
end

