require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class Admin::BlogPosts5IntegrationTest < ActionController::IntegrationTest
  def test_search_retains_filter
    user1 = User.find_or_create_by_username 'friedrich'
    user2 = User.find_or_create_by_username 'rene'

    BlogPost.create! :title => "God is dead", :user => user1
    blog_post2 = BlogPost.create! :title => "I think therefore I am", :user => user2


    visit "/admin/blog_posts5"
    click_link "friedrich"
    fill_in "search", :with => 'I think therefore I am'
    click_button 'Search'
    
    assert_select 'a[href=?]', "/admin/blog_posts5/edit/#{blog_post2.id}", false
  end
end
