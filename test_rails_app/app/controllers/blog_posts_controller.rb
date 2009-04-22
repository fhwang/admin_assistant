class BlogPostsController < ApplicationController
  def show
    @blog_post = BlogPost.find_by_id params[:id]
  end
end
