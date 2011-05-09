class Admin::Comments2Controller < ApplicationController
  layout 'admin'

  admin_assistant_for Comment do |a|
    a.index do |index|
      index.conditions 'blog_posts.published_at is not null'
      index.include    :blog_post
    end
    
    a.form do |form|
      form[:comment].write_once
    end
  end
end
