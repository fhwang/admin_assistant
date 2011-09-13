TestApp::Application.routes.draw do
  namespace :admin do
    resources :comments
    resources :users
  end
  
  resources :blog_posts
end
