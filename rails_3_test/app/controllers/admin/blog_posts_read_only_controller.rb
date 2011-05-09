class Admin::BlogPostsReadOnlyController < ApplicationController
  layout 'admin'
  
  admin_assistant_for BlogPost do |a|
    a.model_class_name = 'blog post'
    a.actions :index, :show
    
    a.show do |show|
      show.columns :user, :title, :body
      show.model_class_name do |blog_post|
        if blog_post.published?
          'published blog post'
        else
          'unpublished blog post'
        end
      end
    end
  end
end
