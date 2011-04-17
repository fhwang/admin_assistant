class BlogPost < ActiveRecord::Base
  validates_presence_of :title
  validates_presence_of :user_id
  
  has_many   :blog_post_tags
  belongs_to :merged_into,
             :class_name => 'BlogPost', :foreign_key => 'merged_into_id'
  has_many   :tags, :through => :blog_post_tags
  belongs_to :user
  
  def published?
    !published_at.nil?
  end
end
