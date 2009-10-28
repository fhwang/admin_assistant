require File.expand_path(File.dirname(__FILE__) + "/../test_helper")

class AdminBlogPosts2IntegrationTest < ActionController::IntegrationTest
  def test_comes_back_to_index_sorted_by_published_at_after_preview_then_create
    user = User.find_or_create_by_username 'soren'
    BlogPost.create! :title => random_word, :user => user
    visit "/admin/blog_posts2"
    click_link "Published at"
    click_link "New blog post"
    fill_in "blog_post[title]", :with => 'Funny ha ha'
    select "soren", :from => "blog_post[user_id]"
    click_button 'Preview'
    click_button 'Update'
    assert_select 'th.asc', :text => 'Published at'
  end
end
