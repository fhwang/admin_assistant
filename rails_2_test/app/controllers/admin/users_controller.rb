class Admin::UsersController < ApplicationController
  layout 'admin'

  admin_assistant_for User do |a|
    a.actions << :destroy
    
    a[:state].input = :us_state
    
    a.index do |index|
      index.columns :id, :username, :password, :tmp_avatar, :first_name,
                    :last_name
      index.right_column_links << lambda { |user|
        [ "New blog post",
          { :controller => '/admin/blog_posts', :action => 'new',
            :blog_post => {:user_id => user.id} } ]
      }
      index.search.default_search_matches_on(
        :username, "concat_ws(' ', users.first_name, users.last_name)"
      )
    end
    
    a.form do |form|
      form.columns :username, :password, :admin_level, :birthday, :state,
                   :tmp_avatar, :force_blog_posts_to_textile, :first_name, :last_name
      form[:admin_level].input = :select
      form[:admin_level].select_choices = %w(normal admin superuser)
      form[:admin_level].select_options = {:include_blank => false}
      form[:birthday].date_select_options =
          {:start_year => Time.now.year-100, :end_year => Time.now.year}
      form[:force_blog_posts_to_textile].input = :select
      form[:force_blog_posts_to_textile].select_options =
          {:include_blank => true}
    end
    
    a[:tmp_avatar].label = 'Avatar'
  end
  
  protected
  
  def after_save(user)
    raise unless user.id
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
end
