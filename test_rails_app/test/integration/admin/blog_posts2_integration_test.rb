require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class Admin::BlogPosts2IntegrationTest < ActionController::IntegrationTest
  def setup
    @user = User.find_or_create_by_username 'soren'
  end
  
  def test_comes_back_to_index_sorted_by_published_at_after_preview_then_create
    BlogPost.create! :title => random_word, :user => @user
    visit "/admin/blog_posts2"
    click_link "Published at"
    click_link "New blog post"
    fill_in "blog_post[title]", :with => 'Funny ha ha'
    select "soren", :from => "blog_post[user_id]"
    click_button 'Preview'
    click_button 'Update'
    assert_select 'th.asc', :text => 'Published at'
  end
  
  def test_create_when_there_are_no_validation_errors
    title = random_word
    post(
      "/admin/blog_posts2/create",
      :blog_post => {
        :title => title, :tags => 'tag1 tag2', :publish => '1',
        :user_id => @user.id
      }
    )
    @blog_post = BlogPost.find_by_title title
    
    # should create a new BlogPost
    assert @blog_post
    
    # should create tags
    assert_equal(2, @blog_post.tags.size)
    %w(tag1 tag2).each do |tag_str|
      assert(@blog_post.tags.any? { |tag| tag.tag == tag_str })
    end
    
    # should set published_at because of the publish flag
    assert @blog_post.published_at
    
    # should set the tags_string
    assert_match(/tag1,tag2/, @blog_post.tags_string)
  end

  def test_create_when_the_user_has_clicked_Preview
    title = random_word
    post(
      "/admin/blog_posts2/create",
      :blog_post => {
        :title => title, :tags => 'tag1 tag2', :publish => '1',
        :user_id => @user.id
      },
      :commit => 'Preview'
    )
    @blog_post = BlogPost.find_by_title title

    # should redirect to the edit page with the preview flag
    assert_redirected_to(
      :action => 'edit', :id => @blog_post.id, :preview => '1'
    )
  end
  
  def test_create_with_a_bad_tag
    @title = random_word
    post(
      "/admin/blog_posts2/create",
      :blog_post => {
        :title => @title, :tags => 'foo bar! baz', :user_id => @user.id
      }
    )
    
    # should not create a new BlogPost
    assert_nil BlogPost.find_by_title(@title)
    
    # should keep the title in the form
    assert_select(
      "input[name=?][value=?]", 'blog_post[title]', @title
    )
    
    # should render a useful error
    assert_select("div.errorExplanation") do
      assert_select 'li', :text => "Tags contain invalid string 'bar!'"
    end
    
    # should highlight the tag string entry
    assert_select("div.fieldWithErrors") do
      assert_select "input[name=?][value=?]", "blog_post[tags]", "foo bar! baz"
    end
  end
end
