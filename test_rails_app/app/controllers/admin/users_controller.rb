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
    
    a.form do |form|
      form.columns :username, :password, :birthday, :state, :tmp_avatar
      form[:birthday].date_select_options = {:start_year => Time.now.year-100, :end_year => Time.now.year}
    end
    
    a[:tmp_avatar].label = 'Avatar'
  end
  
  protected
  
  def after_save(user)
    if user.tmp_avatar
      user.update_attribute('avatar_version', user.avatar_version + 1)
      user.save
    end
  end
  
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
  
  def destroy_tmp_avatar_in_attributes(attributes)
    attributes[:has_avatar] = false
  end
  
  def tmp_avatar_exists?(user)
    user.has_avatar?
  end
  
  def tmp_avatar_url(user)
    "http://my-image-server.com/users/#{user.id}.jpg?v=#{user.avatar_version}"
  end
end
