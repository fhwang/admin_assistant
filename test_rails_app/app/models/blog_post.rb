class BlogPost < ActiveRecord::Base
  validates_presence_of :title
  
  has_many :blog_post_tags
  has_many :tags, :through => :blog_post_tags
end
