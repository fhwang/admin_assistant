require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class Admin::BlogPosts6IntegrationTest < ActionController::IntegrationTest
  def setup
    User.destroy_all
    @user = User.create! :username => 'soren'
  end
  
  def test_index_when_there_is_one_record_and_15_or_less_users
    BlogPost.destroy_all
    @blog_post = BlogPost.create!(
      :title => "blog post title", :body => 'blog post body',
      :user => @user
    )
    tag1 = Tag.find_or_create_by_tag 'tag1'
    BlogPostTag.create! :blog_post => @blog_post, :tag => tag1
    tag2 = Tag.find_or_create_by_tag 'tag2'
    BlogPostTag.create! :blog_post => @blog_post, :tag => tag2
    User.count.downto(15) do
      user = User.find(:first, :conditions => ['id != ?', @user.id])
      user.destroy
    end
    
    BlogPost.create!(
      :title => "return nil", :body => 'blog post body', :user => @user
    )
    get "/admin/blog_posts6"
    assert_response :success
    
    # should show a link to /admin/comments/new because extra_right_column_links_for_index is defined in the helper
    assert_select('td') do
      assert_select(
        "a[href=?]",
        "/admin/comments/new?comment[blog_post_id]=#{@blog_post.id}",
        :text => "New comment"
      )
    end
  end
end
