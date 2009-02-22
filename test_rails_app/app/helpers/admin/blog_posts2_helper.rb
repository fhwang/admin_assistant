module Admin::BlogPosts2Helper
  def tags_value(blog_post)
    blog_post.tags.map { |tag| tag.tag }.join ' '
  end
end
