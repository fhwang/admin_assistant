module Admin::BlogPosts2Helper
  def tags_html_for_form(blog_post)
    text_field_tag(
      'blog_post[tags]', blog_post.tags.map { |tag| tag.tag }.join(' ')
    )
  end
  
  def tags_html_for_index(blog_post)
    blog_post.tags.map { |tag| tag.tag }.join ' '
  end
end
