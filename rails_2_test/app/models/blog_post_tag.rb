class BlogPostTag < ActiveRecord::Base
  belongs_to :blog_post
  belongs_to :tag
  
  validates_uniqueness_of :blog_post_id, :scope => :tag_id
end
