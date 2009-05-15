class Admin::UsersController < ApplicationController
  layout 'admin'

  admin_assistant_for User do |a|
    a.actions << :destroy
    
    # If you're in a hurry you don't have to send this to the form builder
    # object 
    a[:state].input = :us_state
    
    a.index do |index|
      # Add a right column link
      index.right_column_links << lambda { |user|
        [ "New blog post",
          { :controller => '/admin/blog_posts', :action => 'new',
            :blog_post => {:user_id => user.id} } ]
      }
    end
  end
  
  protected
  
  # Run before a user is created
  def before_create(user)
    user.reset_password
  end
  
  # If 'reset_password' is checked, reset the password
  def before_update(user)
    if params[:reset_password]
      user.reset_password
    end
  end
end
