module Admin::BlogPosts2Helper
  def extra_right_column_links_for_index(blog_post)
    link_to(
      'New comment',
      {
        :controller => 'admin/comments', :action => 'new',
        :comment => {:blog_post_id => blog_post.id}
      }
    )
  end
  
  def tags_string(blog_post)
    blog_post.tags.map { |tag| tag.tag }.join ' '
  end
  
  def user_td_css_class_for_index(blog_post)
    'custom_td_css_class'
  end

  def tr_css_class_for_index(blog_post)
    'custom_tr_css_class'
  end
end
