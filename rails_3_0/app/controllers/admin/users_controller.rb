class Admin::UsersController < ApplicationController
  layout 'admin'

  admin_assistant_for User do |a|
    a.actions << :destroy
    
    a[:state].input = :us_state
    
    a.index do |index|
      index.columns :id, :username, :password, :first_name, :last_name
      index.right_column_links << lambda { |user|
        [ "New blog post",
          { :controller => '/admin/blog_posts', :action => 'new',
            :blog_post => {:user_id => user.id} } ]
      }
      if ActiveRecord::Base.connection.adapter_name == 'MySQL'
        index.search.default_search_matches_on(
          :username, "concat(users.first_name, ' ', users.last_name)"
        )
      else
        index.search.default_search_matches_on(
          :username, "users.first_name || ' ' || users.last_name"
        )
      end
    end
    
    a.form do |form|
      form.columns :username, :password, :admin_level, :birthday, :state,
                   :force_blog_posts_to_textile, :first_name, :last_name
      form[:admin_level].input = :select
      form[:admin_level].select_choices = %w(normal admin superuser)
      form[:admin_level].select_options = {:include_blank => false}
      form[:birthday].date_select_options =
          {:start_year => Time.now.year-100, :end_year => Time.now.year}
      form[:force_blog_posts_to_textile].input = :select
      form[:force_blog_posts_to_textile].select_options =
          {:include_blank => true}
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
