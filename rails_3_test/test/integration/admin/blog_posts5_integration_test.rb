require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class Admin::BlogPosts5IntegrationTest < ActionController::IntegrationTest
  def setup
    User.destroy_all
    @soren = User.create! :username => 'soren'
    @jean = User.create! :username => 'jean'
  end
  
  def test_create_with_title_alt
    post(
      "/admin/blog_posts5",
      :blog_post => {
        :user_id => @soren.id, :title => '', :title_alt => 'alternate field'
      }
    )
    assert_response :redirect
    
    # should use the value of title alt for the title
    bp = BlogPost.last
    assert_equal('alternate field', bp.title)
  end
  
  def test_index
    BlogPost.create!(
      :published_at => Time.utc(2009, 9, 1, 12, 30, 0), :user => @soren,
      :title => 'whatever'
    )
    BlogPost.create!(
      :published_at => Time.utc(2009, 9, 1, 12, 30, 0), :user => @soren,
      :title => 'just do it'
    )
    get "/admin/blog_posts5"
    assert_response :success
    
    # should render the filter.html.erb partial
    assert_select('ul.aa_filter')
    assert_select('ul.aa_filter li a', :text => "soren")
    assert_select('td', :text => "whatever")
    assert_select('td', :text => "just do it")
  end
  
  def test_index_filter
    BlogPost.create!(
      :published_at => Time.utc(2009, 9, 1, 12, 30, 0), :user => @soren,
      :title => 'whatever'
    )
    BlogPost.create!(
      :published_at => Time.utc(2009, 9, 1, 12, 30, 0), :user => @soren,
      :title => 'whatever'
    )
    
    get "/admin/blog_posts5?filter=#{@soren.id}"
    assert_response :success
    
    # should filter blog posts by user id
    assert_select('td', :text => "whatever")
    assert_no_match(%r|<td[^>]*>just do it</td>|, response.body)
  end
  
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
