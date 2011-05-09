require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class Admin::BlogPostsCustomNewAndEditIntegrationTest <
      ActionController::IntegrationTest
  def setup
    User.destroy_all
    @user = User.create! :username => 'soren'
  end
  
  def test_index_with_one_blog_psot
    BlogPost.destroy_all
    @blog_post = BlogPost.create!(
      :title => "hi there", :user => @user, :textile => false
    )
      
    get "/admin/blog_posts_custom_new_and_edit"
    assert_response :success
    
    # should have a new link
    assert_select(
      "a[href=/admin/blog_posts_custom_new_and_edit/new]", 'New blog post'
    )
      
    # should have an edit link
    assert_select('td.actions') do
      assert_select(
        "a[href=/admin/blog_posts_custom_new_and_edit/#{@blog_post.id}/edit]",
        'Edit'
      )
    end

    # should have a destroy link
    assert_select('td.actions') do
      assert_select(
        "a.destroy[href=?][data-method=?]",
        "/admin/blog_posts_custom_new_and_edit/#{@blog_post.id}",
        'delete',
        :text => 'Delete'
      )
    end

    # should have a show link
    assert_select('td.actions') do
      assert_select(
        "a[href=/admin/blog_posts_custom_new_and_edit/#{@blog_post.id}]",
        'Show'
      )
    end
  end
  
  def test_index_with_helper_methods_suppressing_links
    BlogPost.destroy_all
    @blog_post = BlogPost.create!(
      :title => "hi there", :user => @user, :textile => false
    )

    get(
      "/admin/blog_posts_custom_new_and_edit",
      :flag_to_trigger_helper_methods => '1'
    )
    assert_response :success
    
    # should not have a new link
    assert_select(
      "a[href=/admin/blog_posts_custom_new_and_edit/new]", false,
      'New blog post'
    )
      
    # should not have an edit link
    assert_select(
      "td.actions a[href=/admin/blog_posts_custom_new_and_edit/edit/#{@blog_post.id}]",
      false,
      'Edit'
    )
    
    # should not have a destroy link
    assert_select("td.actions a[href=#]", false, 'Delete')

    # should not have a show link
    assert_select(
      "td.actions a[href=/admin/blog_posts_custom_new_and_edit/show/#{@blog_post.id}]", 
      false,
      'Show'
    )
    
    # should not have a search link
    assert_no_match(%r|<a[^>]*>Search</a>|, response.body)
  end
end
