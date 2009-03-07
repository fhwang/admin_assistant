class BlogPost < ActiveRecord::Base
  validates_presence_of :title
  validates_presence_of :user_id
  
  has_many   :blog_post_tags
  has_many   :tags, :through => :blog_post_tags
  belongs_to :user
end
