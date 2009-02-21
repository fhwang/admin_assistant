class BlogPostTag < ActiveRecord::Base
  belongs_to :blog_post
  belongs_to :tag
end
