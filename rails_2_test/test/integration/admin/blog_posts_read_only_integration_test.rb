require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class Admin::BlogPostsReadOnlyIntegrationTest < 
      ActionController::IntegrationTest
  def setup
    User.destroy_all
    @user = User.create! :username => 'soren'
  end
  
  def test_index
    BlogPost.destroy_all
    @blog_post = BlogPost.create!(
      :title => "hi there", :user => @user, :textile => false
    )
    get "/admin/blog_posts_read_only"
    
    # should be successful
    assert_response :success
    
    # should not have a new link
    assert_no_match(%r|<a[^>]*>New blog post</a>|, response.body)
    
    # should not make the textile field an Ajax toggle
    assert_select(
      "div[id=?]", "blog_post_#{@blog_post.id}_textile", false
    )
    
    # should have a show link
    assert_select(
      "a[href=/admin/blog_posts_read_only/show/#{@blog_post.id}]", 'Show'
    )
  end
  
  def test_show_for_a_published_blog_post
    @blog_post = BlogPost.create!(
      :title => 'published', :user => @user, :published_at => Time.now.utc,
      :body => 'Today I ate a sandwich.'
    )
    get "/admin/blog_posts_read_only/show/#{@blog_post.id}"
    
    # should not show textile
    assert_no_match(/Textile/, response.body)
    
    # should use the block for the title
    assert_select(
      'h2', :text => "Published blog post #{@blog_post.id}"
    )
    
    # should not show an edit link
    assert_select(
      'a[href=?]', "/admin/blog_posts_read_only/edit/#{@blog_post.id}", false
    )
    
    # should use the custom partial to render the body
    assert_select('strong', :text => 'Today I ate a sandwich.')
  end
  
  def test_show_for_an_unpublished_blog_post
    @blog_post = BlogPost.create!(
      :title => 'unpublished', :user_id => @user.id, :published_at => nil
    )
    get "/admin/blog_posts_read_only/show/#{@blog_post.id}"
    
    # should use the block for the title
    assert_select(
      'h2', :text => "Unpublished blog post #{@blog_post.id}"
    )
  end
end
