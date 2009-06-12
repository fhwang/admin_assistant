class Admin::BlogPostsReadOnlyController < ApplicationController
  layout 'admin'
  
  admin_assistant_for BlogPost do |a|
    a.actions :index, :show
  end
end
