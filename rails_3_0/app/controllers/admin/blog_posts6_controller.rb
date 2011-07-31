class Admin::BlogPosts6Controller < ApplicationController
  layout 'admin'

  admin_assistant_for BlogPost do |a|
    a.actions.delete :create
    a.actions.delete :update
    a.actions.delete :show
  end
  
end
