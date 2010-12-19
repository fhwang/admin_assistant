require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class Admin::CommentsIntegrationTest < ActionController::IntegrationTest
  def test_edit
    @comment = Comment.create! :comment => "you think you're so smart"
    get "/admin/comments/edit/#{@comment.id}"
    
    # should not allow the comments to be editable
    assert_match(/you think you're so smart/, response.body)
    assert_select('textarea', false)
  end
  
  def test_index_with_a_comment_without_the_word_smart
    Comment.create! :comment => "something else"
    get "/admin/comments"
    
    # should not include the index
    assert_no_match(/something else/, response.body)
  end
  
  def test_index_when_searching_by_comment
    @comment = Comment.create! :comment => "you think you're so smart"
    get "/admin/comments", :search => 'you'
    
    # should find the comment
    assert_match(/you think you're so smart/, response.body)
  end
  
  def test_index_when_searching_by_ID
    @comment = Comment.create! :comment => "you think you're so smart"
    get "/admin/comments", :search => @comment.id.to_s
    
    # should find the comment
    assert_match(/you think you're so smart/, response.body)
  end
  
  def test_new_with_at_least_16_blog_posts_and_16_users
    user = User.find_or_create_by_username 'soren'
    BlogPost.count.upto(16) do
      BlogPost.create! :title => random_word, :user => user
    end
    User.count.upto(16) do
      User.create! :username => random_word
    end
    get "/admin/comments/new"
    
    # should be a success
    assert_response :success
  end
end
