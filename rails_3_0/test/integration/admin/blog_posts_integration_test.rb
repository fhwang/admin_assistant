require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class Admin::BlogPostsIntegrationTest < ActionController::IntegrationTest
  def setup
    User.destroy_all
    @user = User.create! :username => 'soren'
  end
  
  def teardown
    # undoing mocking done for test_index_with_100_000_records
    def BlogPost.paginate(*args)
      super
    end
  end
  
  def test_autocomplete_user
    @bill1 = User.create! :username => 'Bill 1'
    @bill2 = User.create! :username => 'Bill 2'
    1.upto(11) do |i|
      User.create! :username => "Bob #{i}"
    end
    User.create! :username => 'Bob'

    get "/admin/blog_posts/autocomplete_user?q=Jane"
    results = JSON.parse(response.body)
    assert results.empty?
      
    get "/admin/blog_posts/autocomplete_user?q=Bill"
    results = JSON.parse(response.body)
    assert_equal(2, results.size)
    assert(
      results.any? { |r| r['id'] == @bill1.id.to_s && r['name'] == 'Bill 1' }
    )
    assert(
      results.any? { |r| r['id'] == @bill2.id.to_s && r['name'] == 'Bill 2' }
    )
    
    get "/admin/blog_posts/autocomplete_user?q=Bob"
    results = JSON.parse(response.body)
    # should return a max of ten users
    assert_equal(10, results.size)
    # should make sure the shortest matches are included in the results
    assert(results.any? { |r| r['name'] == 'Bob' })
  end
  
  def test_back_to_index_comes_back_to_index_sorted_by_published_at
    user = User.find_or_create_by_username 'soren'
    BlogPost.create! :title => random_word, :user => user
    visit "/admin/blog_posts"
    click_link "Published at"
    click_link "New blog post"
    click_link "Back to index"
    assert_select 'th.asc', :text => 'Published at'
  end
  
  def test_comes_back_to_index_sorted_by_published_at_after_successful_creation
    user = User.find_or_create_by_username 'soren'
    BlogPost.create! :title => random_word, :user => user
    visit "/admin/blog_posts"
    click_link "Published at"
    click_link "New blog post"
    fill_in "blog_post[title]", :with => 'Funny ha ha'
    select "soren", :from => "blog_post[user_id]"
    click_button 'Create'
    assert_select 'th.asc', :text => 'Published at'
  end
  
  def test_create_when_there_are_no_validation_errors
    title = random_word
    post(
      "/admin/blog_posts",
      :blog_post => {
        :title => title, :textile => '1', :user_id => @user.id,
        'published_at(1i)' => '', 'published_at(2i)' => '',
        'published_at(3i)' => '', 'published_at(4i)' => '',
        'published_at(5i)' => ''
      }
    )
    @blog_post = BlogPost.find_by_title(title)
  
    # should create a new BlogPost
    assert_not_nil(@blog_post)
    assert(@blog_post.textile?)
    
    # should not set published_at
    assert_nil(@blog_post.published_at)
  end
  
  def test_create_when_there_are_validation_errors
    post(
      "/admin/blog_posts",
      :blog_post => {:title => ''}, :origin => '/admin/blog_posts'
    )
      
    # should not create a new BlogPost
    assert_nil(BlogPost.find_by_title(''))
    
    # should print all the errors
    assert_response :success
    assert_match(/Title can't be blank/, response.body)
    
    # should show a link back to the index page
    assert_select("a[href=/admin/blog_posts]", 'Back to index')
  end
  
  def test_destroy
    # should be an unknown action
    assert_raises(AbstractController::ActionNotFound) do
      delete "/admin/blog_posts/123"
    end
  end
  
  def test_edit
    @blog_post = BlogPost.create! :title => random_word, :user => @user
    
    visit "/admin/blog_posts"
    click_link "Edit"

    # should show a form
    assert_match(
      %r|<form[^>]*action="/admin/blog_posts/#{@blog_post.id}".*input.*name="blog_post\[title\]"|m,
      response.body
    )
    
    # should prefill the values
    assert_match(%r|input.*value="#{@blog_post.title}"|, response.body)
      
    # should show a link back to the index page
    assert_select("a[href=/admin/blog_posts]", 'Back to index')
  end

  def test_edit_when_there_is_a_referer_value_on_the_request
    # should have the origin hidden input value
    blog_post = BlogPost.create! :title => random_word, :user => @user
    visit "/admin/blog_posts"
    click_link 'Published at'
    click_link 'Edit'
    assert_select(
      "input#origin[value=?]", 
      "/admin/blog_posts?sort=published_at&amp;sort_order=asc"
    )
  end

  def test_edit_when_there_are_more_than_15_users
    @blog_post = BlogPost.create! :title => random_word, :user => @user
    1.upto(16) do |i|
      User.create! :username => "--user #{i}--"
    end
    get "/admin/blog_posts/#{@blog_post.id}/edit"
    
    # should use the token input instead of a drop-down
    assert_select("select[name=?]", "blog_post[user_id]", false)
    assert_select("input[name=?][value=?]", 'blog_post[user_id]', @user.id)
    assert_match(
      %r|
        \$\("\#blog_post_user_id"\)\.tokenInput\(
        \s*"/admin/blog_posts/autocomplete_user",
        .*prePopulate
        .*"id":\s*#{@user.id}
      |mx,
      response.body
    )
  end
  
  def test_edit_when_there_are_less_than_15_users
    @blog_post = BlogPost.create! :title => random_word, :user => @user
    User.count.downto(14) do
      user = User.find(
        :first, :conditions => ['username != ?', @user.username]
      )
      user.destroy
    end
    get "/admin/blog_posts/#{@blog_post.id}/edit"
    
    # should use a drop-down with a blank option
    assert_select('select[name=?]', 'blog_post[user_id]') do
      assert_select "option[value='']"
    end
  end

  def test_index_when_there_are_no_records
    BlogPost.destroy_all
    get "/admin/blog_posts"
    assert_response :success

    # should say "No blog posts found"
    assert_match(/No blog posts found/, response.body)
      
    # should say the name of the model you're editing
    assert_match(/Blog posts/, response.body)
      
    # should have a new link
    assert_select(
      "a[href=/admin/blog_posts/new]", 'New blog post'
    )
      
    # should have a search form
    assert_select("a#show_search_form", :text => 'Search')
      
    # should use the admin layout
    assert_match(/admin_assistant sample Rails app/, response.body)
      
    # should use the default admin_assistant CSS
    assert_select(
      'link[href^=/stylesheets/admin_assistant/default.css]'
    )
  end
  
  def test_index_when_there_is_one_record
    BlogPost.destroy_all
    @blog_post = BlogPost.create!(
      :title => "hi there", :user => @user, :textile => false
    )
    get "/admin/blog_posts"
    assert_response :success
    
    # should show title by default
    assert_match(/hi there/, response.body)
      
    # should say the name of the model you're editing
    assert_match(/Blog posts/, response.body)
      
    # should have a new link
    assert_select(
      "a[href=/admin/blog_posts/new]", 'New blog post'
    )
      
    # should have an edit link
    assert_select('td.actions') do
      assert_select "a[href=/admin/blog_posts/#{@blog_post.id}/edit]", 'Edit'
    end
      
    # should have a show link
    assert_select(
      "a[href=/admin/blog_posts/#{@blog_post.id}]", 'Show'
    )
      
    # should show sort links
    pretty_column_names = {
      'id' => 'ID', 'title' => 'Title', 'body' => 'Body', 'user' => 'User'
    }
    pretty_column_names.each do |field, pretty_column_name|
      assert_a_tag_with_get_args(
        pretty_column_name, '/admin/blog_posts',
        {:sort => field, :sort_order => 'asc'}, response.body
      )
    end
      
    # should show pretty column headers
    column_headers = ['ID', 'Title', 'Body', 'User']
    column_headers.each do |column_header|
      assert_select('th') do
        assert_select 'a', column_header
      end
    end
      
    # should say how many records are found
    assert_select(
      'div.aa_footer', :text => '1 blog post found'
    )
      
    # should say username because that's one of our default name fields
    assert_select('td', :text => 'soren')
    
    # should make the textile field an Ajax toggle
    toggle_div_id = "blog_post_#{@blog_post.id}_textile"
    post_url =
        "/admin/blog_posts/#{@blog_post.id}?" +
        'blog_post[textile]' + "=1&amp;from=#{toggle_div_id}"
    assert_select("div[id=?]", toggle_div_id) do
      assert_select('a.toggle[href=?]', post_url, :text => 'false')
    end

    # should not show the page selector form
    assert_select('.pagination') do
      assert_select('form[method=get][action=/admin/blog_posts]', false)
    end
      
    # should have a tbody with the ID blog_posts_index_tbody
    assert_select('tbody#blog_posts_index_tbody')
      
    # should have a tr with the ID based on @blog_post.id
    assert_select("tr[id=blog_post_#{@blog_post.id}]")
      
    # should not show created_at or updated_at by default
    assert_no_match(/Created at/, response.body)
    assert_no_match(/Updated at/, response.body)
  end
  
  def test_index_when_there_is_one_record_that_somehow_has_a_nil_User
    @blog_post = BlogPost.create! :title => "hi there", :user => @user
    BlogPost.update_all "user_id = null"
    get "/admin/blog_posts"
      
    # should be fine with a nil User
    assert_response :success
  end
    
  def test_index_when_there_are_more_than_10_pages_of_results
    BlogPost.count.upto(251) do
      @blog_post = BlogPost.create!(
        :title => "hi there", :user => @user, :textile => false
      )
    end
    get "/admin/blog_posts"
      
    # should show the page selector form at the bottom
    assert_select('.pagination') do
      assert_select('form[method=get][action=/admin/blog_posts]') do
        assert_select 'input[name=page]'
      end
    end
  end
  
  def test_index_sorting_when_there_are_two_records
    BlogPost.destroy_all
    @blog_post1 = BlogPost.create!(
      :title => "title 1", :body => "body 2", :user => @user
    )
    @blog_post2 = BlogPost.create!(
      :title => "title 2", :body => "body 1", :user => @user
    )

    get "/admin/blog_posts", :sort => 'title', :sort_order => 'asc'
    assert_response :success
        
    # should sort by title asc
    assert_match(%r|title 1.*title 2|m, response.body)
      
    # should show a desc sort link for title
    assert_a_tag_with_get_args(
      'Title', '/admin/blog_posts',
      {:sort => 'title', :sort_order => 'desc'}, response.body
    )
        
    # should show asc sort links for other fields
    pretty_column_names = {'id' => 'ID', 'body' => 'Body'}
    pretty_column_names.each do |field, pretty_column_name|
      assert_a_tag_with_get_args(
        pretty_column_name, '/admin/blog_posts',
        {:sort => field, :sort_order => 'asc'}, response.body
      )
    end
        
    # should use the right CSS classes in the title header
    assert_select('th[class="sort asc"]') do
      assert_select 'a', :text => 'Title'
    end
        
    # should have no CSS sorting classes in the header for ID
    assert_select('th:not([class])') do
      assert_select 'a', :text => 'ID'
    end
        
    # should mark the title cells with CSS sorting classes
    assert_select('td[class="sort"]', :text => 'title 1')
      
    get "/admin/blog_posts", :sort => 'title', :sort_order => 'desc'
    assert_response :success
        
    # should sort by title desc
    assert_match(%r|title 2.*title 1|m, response.body)
      
    # should show a no-sort link for title
    assert_select("a[href=/admin/blog_posts]", 'Title')
        
    # should show asc sort links for other fields
    pretty_column_names = {'id' => 'ID', 'body' => 'Body'}
    pretty_column_names.each do |field, pretty_column_name|
      assert_a_tag_with_get_args(
        pretty_column_name, '/admin/blog_posts',
        {:sort => field, :sort_order => 'asc'}, response.body
      )
    end
        
    # should use the right CSS classes in the title header
    assert_select('th[class="sort desc"]') do
      assert_select 'a', :text => 'Title'
    end
        
    # should have no CSS sorting classes in the header for ID
    assert_select('th:not([class])') do
      assert_select 'a', :text => 'ID'
    end
        
    # should mark the title cells with CSS sorting classes
    assert_select('td[class="sort"]', :text => 'title 1')
  end
  
  def test_index_sorting_by_user
    BlogPost.destroy_all
    jean_paul = User.create! :username => 'jean-paul'
    BlogPost.create!(
      :title => 'title 1', :body => 'body 1', :user => @user
    )
    BlogPost.create!(
      :title => 'title 2', :body => 'body 2', :user => jean_paul
    )
      
    get "/admin/blog_posts", :sort => 'user', :sort_order => 'asc'
    assert_response :success
        
    # should show jean-paul's blog post before soren's
    assert_match(%r|jean-paul.*soren|m, response.body)
        
    # should use the right CSS classes in the user header
    assert_select('th[class="sort asc"]') do
      assert_select 'a', :text => 'User'
    end
        
    # should mark the title cells with CSS sorting classes
    assert_select('td[class="sort"]', :text => 'jean-paul')
      
    # should show a desc sort link for user
    assert_a_tag_with_get_args(
      'User', '/admin/blog_posts',
      {:sort => 'user', :sort_order => 'desc'}, response.body
    )
      
    get "/admin/blog_posts", :sort => 'user', :sort_order => 'desc'
    assert_response :success
        
    # should show soren's blog post before jean-paul's
    assert_match(%r|soren.*jean-paul|m, response.body)
  end
  
  def test_index_search_when_there_are_no_records
    BlogPost.destroy_all
    get "/admin/blog_posts", :search => 'foo'
    assert_response :success

    # should say 'No blog posts found'
    assert_match(/No blog posts found/, response.body)
    
    # should display the search with the terms
    assert_select("form#search_form");
    assert_match(
      %r|<script.*\$\('#show_search_form'\).click\(\);|m,
      response.body
    )
    assert_match(%r|input.*value="foo"|, response.body)
    
    # should show a link back to the index page
    assert_select("a[href=/admin/blog_posts]", 'Back to index')
  end

  def test_index_search_when_there_are_no_records_that_match
    BlogPost.destroy_all
    BlogPost.create!(
      :title => 'no match', :body => 'no match', :user => @user
    )
    get "/admin/blog_posts", :search => 'foo'
    assert_response :success
      
    # should say 'No blog posts found'
    assert_match(/No blog posts found/, response.body)
  end
  
  def test_index_search_when_there_is_a_blog_post_with_a_matching_title
    BlogPost.destroy_all
    BlogPost.create!(
      :title => 'foozy', :body => 'blog post body', :user => @user
    )
    get "/admin/blog_posts", :search => 'foo'
    assert_response :success
    
    # should show that blog post
    assert_match(/blog post body/, response.body)
  end
  
  def test_index_search_when_there_is_a_matching_body
    BlogPost.destroy_all
    BlogPost.create!(
      :title => 'blog post title', :body => 'barfoo', :user => @user
    )
    get "/admin/blog_posts", :search => 'foo'
    assert_response :success

    # should show that blog post
    assert_match(/blog post title/, response.body)
      
    # should say how many records are found
    assert_match(/1 blog post found/, response.body)
  end
  
  def test_index_pagination_with_51_records_when_looking_at_the_first_page
    BlogPost.destroy_all
    1.upto(51) do |i|
      BlogPost.create!(
        :title => "title -#{i}-", :body => "body -#{i}-", :user => @user
      )
    end
      
    get "/admin/blog_posts"
    assert_response :success
      
    # should have a link to the next page
    assert_will_paginate_link("/admin/blog_posts", 2, 'Next &#8594;')
    assert_will_paginate_link("/admin/blog_posts", 2, '2')
      
    # should not have a link to the previous page
    assert_select(
      "a[href=/admin/blog_posts?page=0]", false, '&#8592; Previous'
    )
    assert_select("a[href=/admin/blog_posts?page=0]", false, '0')
      
    # should the full number of posts found
    assert_match(/51 blog posts found/, response.body)
  end

  def test_index_pagination_with_51_records_when_looking_at_the_second_page
    BlogPost.destroy_all
    1.upto(51) do |i|
      BlogPost.create!(
        :title => "title -#{i}-", :body => "body -#{i}-", :user => @user
      )
    end
      
    get "/admin/blog_posts", :page => '2'
    assert_response :success
  
    # should have a link to the next page
    assert_will_paginate_link("/admin/blog_posts", 3, 'Next &#8594;')
    assert_will_paginate_link("/admin/blog_posts", 3, '3')
  
    # should have a link to the previous page
    assert_will_paginate_link("/admin/blog_posts", 1, '&#8592; Previous')
    assert_will_paginate_link("/admin/blog_posts", 1, '1')
  
    # should the full number of posts found
    assert_match(/51 blog posts found/, response.body)
  end

  def test_index_pagination_with_51_records_when_looking_at_the_third_page
    BlogPost.destroy_all
    1.upto(51) do |i|
      BlogPost.create!(
        :title => "title -#{i}-", :body => "body -#{i}-", :user => @user
      )
    end
    
    get "/admin/blog_posts", :page => '3'
    assert_response :success

    # should not have a link to the next page
    assert_select(
      "a[href=/admin/blog_posts?page=4]", false, 'Next &#8594;'
    )
    assert_select("a[href=/admin/blog_posts?page=3]", false, '3')
  
    # should have a link to the previous page
    assert_will_paginate_link("/admin/blog_posts", 2, '&#8592; Previous')
    assert_will_paginate_link("/admin/blog_posts", 2, '2')
  
    # should the full number of posts found
    assert_match(/51 blog posts found/, response.body)
  end
  
  def test_index_with_100_000_records
    BlogPost.count.upto(25) do |i|
      BlogPost.create!(
        :title => "title -#{i}-", :body => "body -#{i}-", :user => @user
      )
    end
    def BlogPost.paginate(*args)
      collection = super(*args)
      collection.total_entries = 100_000
      collection
    end
    
    get "/admin/blog_posts"
    
    # should not offer a link to sort by user
    assert_no_a_tag_with_get_args(
      'User', '/admin/blog_posts', {:sort => 'user', :sort_order => 'asc'},
      response.body
    )
  end
  
  def test_new
    @alfie = User.find_or_create_by_username 'alfie'
    visit "/admin/blog_posts"
    click_link "New blog post"

    # should show a form
    assert_match(
      %r|<form[^>]*action="/admin/blog_posts".*input.*name="blog_post\[title\]"|m,
      response.body
    )
    
    if ENV['AA_CONFIG'] == '2'
      # if you're using AA config 2, text columns are rendered as inputs, not 
      # textareas, by default
      assert_select("input[name=?]", "blog_post[body]")
    else
      # by default, should use a textarea for the body field
      assert_match(
        %r|<textarea.*name="blog_post\[body\]".*>.*</textarea>|, response.body
      )
    end
      
    # should show a link back to the index page
    assert_select("a[href=/admin/blog_posts]", 'Back to index')
      
    # should show pretty field names
    field_names = ['Title', 'Body']
    field_names.each do |field_name|
      assert_select('label', field_name)
    end

    # should set the for attribute of the labels
    field_names = ['Title', 'Body']
    field_names.each do |field_name|
      assert_select("label[for=blog_post_#{field_name.downcase}]")
    end
    
    # should use a checkbox for the boolean field 'textile'
    assert_match(
      %r!
        <input[^>]*
        (name="blog_post\[textile\][^>]*type="checkbox"|
         type="checkbox"[^>]*name="blog_post\[textile\])
      !x,
      response.body
    )
    
    # should use a drop-down for the user field
    assert_select("select[name=?]", "blog_post[user_id]") do
      assert_select "option:nth-child(1)[value='']"
      assert_select "option:nth-child(2)[value=?]", @alfie.id, :text => 'alfie'
      assert_select "option:nth-child(3)[value=?]", @user.id, :text => 'soren'
    end
    
    # should set the controller path as a CSS class
    assert_select("div[class~=admin_blog_posts]")
    
    # should use dropdowns with nil defaults for published_at
    nums_and_dt_fields = {
      1 => :year, 2 => :month, 3 => :day, 4 => :hour, 5 => :min
    }
    nums_and_dt_fields.each do |num, dt_field|
      name = "blog_post[published_at(#{num}i)]"
      value_for_now_option = Time.now.send(dt_field).to_s
      if [:hour, :min].include?(dt_field) && value_for_now_option.size == 1
        value_for_now_option = "0#{value_for_now_option}"
      end
      assert_select('select[name=?]', name) do
        assert_select "option[value='']"
        assert_select "option:not([selected])[value=?]", value_for_now_option
      end
    end
    
    # should show a clear link for published_at
    assert_select('a', :text => "Clear")
  end
  
  def test_new_with_a_preset_value_in_the_GET_arguments
    get "/admin/blog_posts/new", :blog_post => {:user_id => @user.id.to_s}
    
    # should set that preselected value
    assert_select("select[name=?]", "blog_post[user_id]") do
      assert_select "option[value=?][selected=selected]",
               @user.id, :text => 'soren'
      assert_select "option[value='']"
    end
  end
  
  def test_new_when_there_are_more_than_15_users
    User.destroy_all
    1.upto(16) do |i|
      User.create! :username => "--user #{i}--"
    end
    get "/admin/blog_posts/new"
    
    # should use the token input instead of a drop-down
    assert_select("select[name=?]", "blog_post[user_id]", false)
    assert_select("input[name=?]", 'blog_post[user_id]')
    assert_match(
      %r|
        \$\("\#blog_post_user_id"\)\.tokenInput\(
        \s*"/admin/blog_posts/autocomplete_user"
      |mx,
      response.body
    )
  end
  
  def test_show
    BlogPost.destroy_all
    @blog_post = BlogPost.create!(
      :title => "foo > bar & baz", :user => @user, :textile => false
    )
    get "/admin/blog_posts/#{@blog_post.id}"
    
    # should show the HTML-escaped title
    assert_match(/foo &gt; bar &amp; baz/, response.body)
    
    # should have a link to edit
    assert_select(
      "a[href=/admin/blog_posts/#{@blog_post.id}/edit]", 'Edit'
    )
    
    # should show soren
    assert_match(/soren/, response.body)
  end
  
  def test_update_when_there_are_no_validation_errors
    @blog_post = BlogPost.create! :title => random_word, :user => @user
    title2 = random_word
    put(
      "/admin/blog_posts/#{@blog_post.id}",
      :blog_post => {
        :title => title2, 'published_at(1i)' => '2009',
        'published_at(2i)' => '1', 'published_at(3i)' => '2',
        'published_at(4i)' => '3', 'published_at(5i)' => '4'
      }
    )
    assert_redirected_to(:action => 'index')
    @blog_post_prime = BlogPost.find_by_title(title2)
  
    # should update a pre-existing BlogPost
    assert_not_nil(@blog_post_prime)
  
    # should set published_at
    assert_equal(Time.utc(2009, 1, 2, 3, 4), @blog_post_prime.published_at)
  end  
    
  def test_update_when_there_are_validation_errors
    @blog_post = BlogPost.create! :title => random_word, :user => @user
    put(
      "/admin/blog_posts/#{@blog_post.id}",
      :blog_post => {:title => ''}, :origin => '/admin/blog_posts'
    )
    
    # should not create a new BlogPost
    assert_nil(BlogPost.find_by_title(''))
    
    # should print all the errors
    assert_response :success
    assert_match(/Title can't be blank/, response.body)
    
    # should show a link back to the index page
    assert_select("a[href=/admin/blog_posts]", 'Back to index')
  end

  def test_update_handles_the_origin_param
    @blog_post = BlogPost.create! :title => random_word, :user => @user
    
    # should redirect to the origin when there is a origin on the form submit
    origin = 'http://foo.com'
    put(
      "/admin/blog_posts/#{@blog_post.id}",
      :blog_post => {:title => 'foo'}, :origin => origin
    )
    assert_redirected_to(origin)
  end
  
  def test_update_as_Ajax_toggle
    @blog_post = BlogPost.create!(
      :title => random_word, :user => @user, :textile => false
    )
    put(
      "/admin/blog_posts/#{@blog_post.id}",
      :from => "blog_post_#{@blog_post.id}_textile",
      :blog_post => {:textile => '1'}
    )

    # should return success
    assert_response :success
    
    # should update the textile field
    assert(@blog_post.reload.textile)
    
    # should only render a small snippet of HTML with Ajax in it
    toggle_div_id = "blog_post_#{@blog_post.id}_textile"
    post_url =
        "/admin/blog_posts/#{@blog_post.id}?" +
        'blog_post[textile]' + "=0&amp;from=#{toggle_div_id}"
    assert_select('div[id=?]', toggle_div_id, false)
    assert_select('a.toggle[href=?]', post_url, :text => 'true')
    assert_no_match(%r|<title>Admin</title>|, response.body)
  end
end
