module Admin::BlogPosts2Helper
  def tags_html_for_index(blog_post)
    blog_post.tags.map { |tag| tag.tag }.join ' '
  end
end
