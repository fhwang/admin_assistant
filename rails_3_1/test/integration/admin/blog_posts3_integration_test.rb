require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class Admin::BlogPosts3IntegrationTest < ActionController::IntegrationTest
  def setup
    User.destroy_all
    @user = User.create! :username => 'soren', :password => 'password'
  end
  
  def test_create_with_no_title
    @orig_blog_post_count = BlogPost.count
    post "/admin/blog_posts3", :blog_post => {:user_id => @user.id}
    
    # should redirect to the index
    assert_redirected_to(:action => 'index')
    
    # should create a new blog post with the title pre-filled as (draft)
    assert_equal(@orig_blog_post_count + 1, BlogPost.count)
    blog_post = BlogPost.last
    assert_equal('(draft)', blog_post.title)
  end
  
  def test_edit
    @blog_post = BlogPost.create! :title => random_word, :user => @user
    get "/admin/blog_posts3/#{@blog_post.id}/edit"
    
    # should have a body field
    if ENV['AA_CONFIG'] == '2'
      assert_select("input[name=?]", "blog_post[body]")
    else
      assert_select('textarea[name=?]', 'blog_post[body]')
    end
    
    # should not include textile
    assert_no_match(/textile/, response.body)
  end
  
  def test_index_with_no_blog_posts
    BlogPost.destroy_all
    get "/admin/blog_posts3"
    assert_response :success

    unless Rails.version =~ /^3.1/
      # should use the activescaffold-themed CSS
      assert_select(
        'link[href^=/stylesheets/admin_assistant/admin_assistant_activescaffold.css]'
      )
    end
  
    # should say 'Posts'
    assert_select('h2', :text => 'Posts')
  end
    
  def test_index_with_one_unpublished_blog_post
    BlogPost.destroy_all
    @blog_post = BlogPost.create!(
      :title => "unpublished blog post", :user => @user,
      :published_at => nil
    )
    $cache.flush
    get "/admin/blog_posts3"
    
    # should show the blog post
    assert_match(/unpublished blog post/, response.body)
    
    # should show 'No' from having called BlogPost#published?
    assert_select("tr[id=blog_post_#{@blog_post.id}]") do
      assert_select "td", :text => 'No'
    end
  
    # should not have a comparator for the ID search field
    assert_select('form[id=search_form][method=get]') do
      assert_select("select[name=?]", "search[id(comparator)]", false)
    end
    
    # should have a blank checkbox for the body search field
    assert_select('form[id=search_form][method=get]') do
      assert_select("input[type=checkbox][name=?]", "search[body(blank)]")
    end
    
    # should render extra action links in order
    assert_match(/Short title.*Blank body/m, response.body)
    
    # should have a trinary select for the has_short_title search field
    assert_select('form[id=search_form][method=get]') do
      assert_select('select[name=?]', 'search[has_short_title]') do
        assert_select("option[value='']", :text => '')
        assert_select("option[value='true']", :text => 'Yes')
        assert_select("option[value='false']", :text => 'No')
      end
    end
  
    # should show a search form with specific fields
    assert_select(
      'form[id=search_form][method=get]', :text => /Title/
    ) do
      assert_select('input[name=?]', 'search[title]')
      assert_select('input[name=?]', 'search[body]')
      assert_select('select[name=?]', 'search[textile]') do
        assert_select("option[value='']", :text => '')
        assert_select("option[value='true']", :text => 'true')
        assert_select("option[value='false']", :text => 'false')
      end
      assert_select('label', :text => 'User')
      assert_select('input[name=?]', 'search[user]')
    end
    
    # should set the count in memcache
    key =
        "AdminAssistant::Admin::BlogPosts3Controller_count_published_at_is_null_"
    assert_equal(1, $cache.read(key))
    assert_in_delta(12.hours, $cache.expires_in(key), 5.seconds)
    
    # should not make the textile field an Ajax toggle
    toggle_div_id = "blog_post_#{@blog_post.id}_textile"
    assert_no_match(%r|new Ajax.Updater\('#{toggle_div_id}'|, response.body)
  end
    
  def test_index_with_a_published_blog_post
    $cache.flush
    BlogPost.destroy_all
    BlogPost.create!(
      :title => "published blog post", :user => @user,
      :published_at => Time.now.utc
    )
    get "/admin/blog_posts3"
    
    # should not show the blog post
    assert_no_match(/published blog post/, response.body)
    assert_match(/No posts found/, response.body)
  end
  
  def test_index_when_searching_by_user
    User.destroy_all
    tiffany = User.create!(:username => 'tiffany')
    BlogPost.create! :title => "By Tiffany", :user => tiffany
    BlogPost.create!(
      :title => "Already published", :user => tiffany,
      :published_at => Time.now
    )
    bill = User.create! :username => 'bill', :password => 'parsimony'
    BlogPost.create! :title => "By Bill", :user => bill
    brooklyn_steve = User.create!(
      :username => 'brooklyn_steve', :state => 'NY'
    )
    BlogPost.create! :title => "By Brooklyn Steve", :user => brooklyn_steve
    sadie = User.create!(
      :username => 'Sadie', :password => 'sadie', :state => 'KY'
    )
    BlogPost.create! :title => "By Sadie", :user => sadie
    get(
      "/admin/blog_posts3",
      :search => {
        :body => "", :textile => "", :id => "", :user => 'ny',
        :has_short_title => ''
      }
    )
    assert_response :success
    
    # should match the string to the username
    assert_match(/By Tiffany/, response.body)
    
    # should match the string to the password
    assert_match(/By Bill/, response.body)
    
    # should match the string to the state
    assert_match(/By Brooklyn Steve/, response.body)
    
    # should skip blog posts that don't match anything on the user
    assert_no_match(/By Sadie/, response.body)
    
    # should skip blog posts that have already been published
    assert_no_match(/Already published/, response.body)
  end
  
  def test_index_with_blog_posts_from_two_different_users
    aardvark_man = User.create!(:username => 'aardvark_man')
    BlogPost.create! :title => 'AARDVARKS!!!!!1', :user => aardvark_man
    ziggurat = User.create!(:username => 'zigguratz')
    BlogPost.create! :title => "Wanna go climbing?", :user => ziggurat
    get "/admin/blog_posts3"
    assert_response :success
      
    # should sort by username
    assert_match(%r|AARDVARKS!!!!!1.*Wanna go climbing|m, response.body)
  end
  
  def test_index_when_searching_for_a_blank_body
    BlogPost.destroy_all
    @nil_body_post = BlogPost.create!(
      :title => "nil", :user => @user, :body => nil
    )
    @empty_string_body_post = BlogPost.create!(
      :title => "empty string", :user => @user, :body => ''
    )
    @non_blank_body_post = BlogPost.create!(
      :title => "non-blank", :user => @user, :body => 'foo'
    )
    get(
      "/admin/blog_posts3",
      :search => {
        "body(blank)" => '1', :user => '', :body => '', :title => '', 
        :textile => '', :id => '', '(all_or_any)' => 'all',
        :has_short_title => ''
      }
    )
    
    # should retrieve a blog post with a nil body
    assert_select("tr[id=?]", "blog_post_#{@nil_body_post.id}")
    
    # should retrieve a blog post with a space-only string body
    assert_select(
      "tr[id=?]", "blog_post_#{@empty_string_body_post.id}"
    )
    
    # should not retrieve a blog post with a non-blank body
    assert_select(
      "tr[id=?]", "blog_post_#{@non_blank_body_post.id}", false
    )
      
    # should have a checked blank checkbox for the body search field
    assert_select('form[id=search_form][method=get]') do
      assert_select(
        "input[type=checkbox][checked=checked][name=?]", 
        "search[body(blank)]"
      )
    end
  end
  
  def test_index_when_searching_for_short_title_blog_posts
    BlogPost.destroy_all
    @bp1 = BlogPost.create!(
      :title => 'short', :body => 'foobar', :user => @user
    )
    @bp2 = BlogPost.create!(
      :title => "longer title", :body => 'foobar', :user => @user
    )
    get(
      "/admin/blog_posts3",
      :search => {
        :body => "", "body(blank)" => '0', :textile => "", :id => "",
        :user => '', :has_short_title => 'true'
      }
    )
    
    # should return a short-titled blog post
    assert_select('td', :text => 'short')
    
    # should not return a longer-title blog post
    assert_no_match(%r|<td[^>]*>longer title</td>|, response.body)
    
    # should pre-select 'true' in the has_short_title search field
    assert_select('form[id=search_form][method=get]') do
      assert_select('select[name=?]', 'search[has_short_title]') do
        assert_select("option[value='']", :text => '')
        assert_select("option[value='true'][selected=selected]", :text => 'Yes')
        assert_select("option[value='false']", :text => 'No')
      end
    end
  end
    
  def test_index_when_searching_for_long_titled_blog_posts
    BlogPost.destroy_all
    @bp1 = BlogPost.create!(
      :title => 'short', :body => 'foobar', :user => @user
    )
    @bp2 = BlogPost.create!(
      :title => "longer title", :body => 'foobar', :user => @user
    )
    get(
      "/admin/blog_posts3",
      :search => {
        :body => "", "body(blank)" => '0', :textile => "", :id => "",
        :user => '', :has_short_title => 'false'
      }
    )

    # should not return a short-titled blog post
    assert_no_match(%r|<td[^>]*>short</td>|, response.body)
    
    # should return a longer-title blog post
    assert_select('td', :text => 'longer title')
    
    # should pre-select 'false' in the has_short_title search field
    assert_select('form[id=search_form][method=get]') do
      assert_select('select[name=?]', 'search[has_short_title]') do
        assert_select("option[value='']", :text => '')
        assert_select("option[value='true']", :text => 'Yes')
        assert_select("option[value='false'][selected=selected]", :text => 'No')
      end
    end
  end
  
  def test_index_when_searching_for_blog_posts_of_any_title_length
    BlogPost.destroy_all
    @bp1 = BlogPost.create!(
      :title => 'short', :body => 'foobar', :user => @user
    )
    @bp2 = BlogPost.create!(
      :title => "longer title", :body => 'foobar', :user => @user
    )
    get(
      "/admin/blog_posts3",
      :search => {
        :body => 'foobar', "body(blank)" => '0', :textile => "", :id => "",
        :user => '', :has_short_title => ''
      }
    )
      
    # should return a short-titled blog post
    assert_select('td', :text => 'short')
  
    # should return a longer-title blog post
    assert_select('td', :text => 'longer title')
  end
  
  def test_index_when_searching_by_id
    BlogPost.destroy_all
    @blog_post1 = BlogPost.create! :title => random_word, :user => @user
    blog_post2 = BlogPost.create! :title => random_word, :user => @user
    BlogPost.update_all(
      "id = #{@blog_post1.id * 10}", "id = #{blog_post2.id}"
    )
    @blog_post2 = BlogPost.find(@blog_post1.id * 10)
    get(
      "/admin/blog_posts3",
      :search => {
        :body => '', "body(blank)" => '0', :textile => "",
        :id => @blog_post1.id.to_s, :user => '', :has_short_title => ''
      }
    )
    
    # should match the record with that ID
    assert_select("tr[id=?]", "blog_post_#{@blog_post1.id}")
    
    # should not match a record with an ID that has the ID as a substring
    assert_select("tr[id=?]", "blog_post_#{@blog_post2.id}", false)
  end
  
  def test_index_when_the_blank_body_count_has_been_cached_in_memcache_but_the_request_is_looking_for_the_default_index
    $cache.flush
    another_key = 
        "AdminAssistant::Admin::BlogPosts3Controller_count__body_is_null_or_body______"
    $cache.write another_key, 1_000_000, :expires_in => 12.hours
    get "/admin/blog_posts3"
    
    # should not read a value from memcache
    assert_no_match(/1000000 posts found/, response.body)

    # should set the count in memcache
    key =
        "AdminAssistant::Admin::BlogPosts3Controller_count_published_at_is_null_"
    assert $cache.read(key)
    assert_in_delta(12.hours, $cache.expires_in(key), 5.seconds)
  end
  
  def test_index_when_the_count_has_been_cached_in_memcache
    BlogPost.create!(:title => "title", :user => @user)
    key =
        "AdminAssistant::Admin::BlogPosts3Controller_count_published_at_is_null_"
    $cache.write key, 1_000_000, :expires_in => 12.hours
    $cache.raise_on_write
    get "/admin/blog_posts3"
    
    # should read memcache and not hit the database
    assert_match(/1000000 posts found/, response.body)
  end
  
  def test_index_with_more_than_one_pages_worth_of_unpublished_blog_posts
    $cache.flush
    BlogPost.destroy_all
    1.upto(26) do |i|
      BlogPost.create!(
        :title => "unpublished blog post #{i}", :user => @user,
        :published_at => nil
      )
    end
    @unpub_count = BlogPost.count "published_at is null"
    $cache.flush
    get "/admin/blog_posts3"
    
    # should cache the total number of entries, not the entries on just this page
    key =
        "AdminAssistant::Admin::BlogPosts3Controller_count_published_at_is_null_"
    assert_equal(@unpub_count, $cache.read(key))
    assert_in_delta(12.hours, $cache.expires_in(key), 5.seconds)
  end
  
  def test_new
    @request_time = Time.now.utc
    get "/admin/blog_posts3/new"
    
    # should not have a body field
    assert_select('textarea[name=?]', 'blog_post[body]', false)
    
    # should have a published_at select that starts in the year 2009
    name = 'blog_post[published_at(1i)]'
    assert_select('select[name=?]', name) do
      assert_select "option[value='2009']"
      assert_select "option[value='2010']"
      assert_select "option[value='2008']", false
    end
    
    # should have a published_at select that is set to now
    name = 'blog_post[published_at(3i)]'
    assert_select('select[name=?]', name) do
      assert_select "option[value=?][selected=selected]", @request_time.day
    end
    
    # should not show a nullify link for published_at
    assert_no_match(%r|<a [^>]*>Set "published at" to nil</a>|, response.body)
    
    # should say 'New post'
    assert_select('h2', :text => 'New post')
  end
  
  def test_show
    @blog_post = BlogPost.create! :title => "title", :user => @user
    get "/admin/blog_posts3/#{@blog_post.id}"
    assert_response :success
    
    # should say 'Post [ID]'
    assert_select('h2', :text => "Post #{@blog_post.id}")
  end
end
