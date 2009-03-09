class Admin::UsersController < ApplicationController
  layout 'admin'

  admin_assistant_for User do |a|
  end
  
  protected
  
  # Run after a user is created
  def after_create(user)
    user.reset_password
    user.save
  end
  
  # If 'reset_password' is checked, reset the password
  def before_update(user)
    if params[:reset_password]
      user.reset_password
    end
  end
end
