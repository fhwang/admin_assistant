class User < ActiveRecord::Base
  has_many :blog_posts
  
  def name_for_admin_assistant
    username
  end
end
