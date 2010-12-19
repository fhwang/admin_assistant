require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class Admin::Comments2IntegrationTest < ActionController::IntegrationTest
  def setup
    @user = User.find_or_create_by_username 'soren'
    @published_blog_post = BlogPost.create!(
      :title => 'published', :user => @user, :published_at => Time.now.utc
    )
    @unpublished_blog_post = BlogPost.create!(
      :title => 'unpublished', :user => @user, :published_at => nil
    )
  end
  
  def test_edit
    @comment = Comment.create!(
      :comment => "you're funny but I'm funnier",
      :blog_post => @published_blog_post
    )
    get "/admin/comments2/edit/#{@comment.id}"
    
    # should not have a textarea for Comment#comment
    assert_select("textarea[name=?]", "comment[comment]", false)
  end
  
  def test_index
    Comment.destroy_all
    @comment_on_published = Comment.create!(
      :comment => "this is published",
      :blog_post => @published_blog_post
    )
    @comment_on_unpublished = Comment.create!(
      :comment => "this was published but no more",
      :blog_post => @unpublished_blog_post
    )
    get "/admin/comments2"
    
    # should show a comment on a published blog post
    assert_select('td', :text => 'this is published')

    # should not show a comment on an unpublished blog post
    assert_no_match(
      %r|<td[^>]*>this was published but no more</td>|, response.body
    )
  end
  
  def test_new
    get "/admin/comments2/new"
    
    # should have a textarea for Comment#comment
    assert_select("textarea[name=?]", "comment[comment]")
  end
end
