module Admin::BlogPosts6Helper
  def extra_right_column_links_for_index(blog_post)
    case blog_post.title
    when "return nil"
      nil
    else
      link_to(
        'New comment',
        {
          :controller => 'admin/comments', :action => 'new',
          :comment => {:blog_post_id => blog_post.id}
        }
      )
    end
  end
end
