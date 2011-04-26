class Admin::BlogPostsController < ApplicationController
  layout 'admin'
  
  # silly class method defined on application.rb, should be available here
  do_something

  admin_assistant_for BlogPost
end

