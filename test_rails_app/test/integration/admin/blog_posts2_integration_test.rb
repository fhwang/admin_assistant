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
  
  def test_create_with_a_bad_tag_and_a_missing_title
    @orig_count = BlogPost.count
    post(
      "/admin/blog_posts2/create",
      :blog_post => {
        :title => '', :tags => 'foo bar! baz', :user_id => @user.id
      }
    )

    # should not create a new BlogPost
    assert_equal(@orig_count, BlogPost.count)
    
    # should render a useful tags error
    assert_select("div.errorExplanation") do
      assert_select 'li', :text => "Tags contain invalid string 'bar!'"
    end
    
    # should highlight the tag string entry
    assert_select("div.fieldWithErrors") do
      assert_select "input[name=?][value=?]", "blog_post[tags]", "foo bar! baz"
    end
    
    # should render a useful title error
    assert_select("div.errorExplanation") do
      assert_select 'li', :text => "Title can't be blank"
    end
    
    # should highlight the title string entry
    assert_select("div.fieldWithErrors") do
      assert_select "input[name=?][value=?]", "blog_post[title]", ""
    end
  end
  
  def test_create_with_a_bad_publish_value_somehow
    @title = random_word
    post(
      "/admin/blog_posts2/create",
      :blog_post => {
        :title => @title, :tags => 'tag1 tag2', :publish => 'FOOBAR',
      }
    )
      
    # should be successful
    assert_response :success
    
    # should not save the blog post
    assert_nil BlogPost.find_by_title(@title)
    
    # should display the publish error
    assert_match(/Publish can't be .*FOOBAR.*/, response.body)
    
    # should display a user error too
    assert_match(/User can't be blank/, response.body)
  end
  
  def test_edit
    BlogPost.destroy_all
    @blog_post = BlogPost.create!(
      :title => "blog post title", :body => 'blog post body', :user => @user
    )
    tag1 = Tag.find_or_create_by_tag 'tag1'
    BlogPostTag.create! :blog_post => @blog_post, :tag => tag1
    tag2 = Tag.find_or_create_by_tag 'tag2'
    BlogPostTag.create! :blog_post => @blog_post, :tag => tag2
    get "/admin/blog_posts2/edit", :id => @blog_post.id
    assert_response :success
    
    # should show the tags
    assert_match(%r|<input.*name="blog_post\[tags\]"|m, response.body)
    assert_match(/(tag2 tag1|tag1 tag2)/, response.body)
    
    # should show a preview button
    assert_select('input[type=submit][value=Preview]')
  end
  
  def test_edit_in_preview_mode
    @blog_post = BlogPost.create!(
      :title => "blog post title", :body => 'blog post body', :user => @user
    )
    get "/admin/blog_posts2/edit", :id => @blog_post.id, :preview => '1'
    assert_response :success

    # should render the preview HTML
    assert_select('html') do
      assert_select 'h4', 'Preview'
    end
  end
  
  def test_edit_when_there_are_more_than_15_users
    @blog_post = BlogPost.create! :title => random_word, :user => @user
    1.upto(16) do |i|
      User.create! :username => "--user #{i}--"
    end
    get "/admin/blog_posts2/edit",:id => @blog_post.id
    
    # should use the restricted autocompleter instead of a drop-down
    assert_select("select[name=?]", "blog_post[user_id]", false)
    assert_select(
      "input[id=user_autocomplete_input][value=soren]"
    )
    assert_select(
      "input[type=hidden][name=?][id=blog_post_user_id][value=?]",
      "blog_post[user_id]", @user.id.to_s
    )
    assert_select("div[id=user_autocomplete_palette]")
    assert_select('div[id=clear_user_link]')
    assert_match(
      %r|
        new\s*AdminAssistant.RestrictedAutocompleter\(
        \s*"user",
        \s*"blog_post_user_id",
        \s*"/admin/blog_posts2/autocomplete_user",
        [^)]*"includeBlank":\s*false
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
    get "/admin/blog_posts2/edit",:id => @blog_post.id
    
    # should use a drop-down without a blank option
    assert_select('select[name=?]', 'blog_post[user_id]') do
      assert_select("option[value='']", false)
    end
  end
  
  def test_edit_a_blog_post_that_has_already_been_published
    @blog_post = BlogPost.create!(
      :title => "blog post title", :body => 'blog post body', :user => @user,
      :published_at => Time.now.utc
    )
    get "/admin/blog_posts2/edit",:id => @blog_post.id
    assert_response :success
    
    # should show the publish check-box checked
    assert_select(
      'input[type=checkbox][name=?][checked=checked]', 'blog_post[publish]'
    )
  end
  
  def test_index_when_there_is_one_record_and_15_or_less_users
    BlogPost.destroy_all
    @blog_post = BlogPost.create!(
      :title => "blog post title", :body => 'blog post body',
      :user => @user
    )
    tag1 = Tag.find_or_create_by_tag 'tag1'
    BlogPostTag.create! :blog_post => @blog_post, :tag => tag1
    tag2 = Tag.find_or_create_by_tag 'tag2'
    BlogPostTag.create! :blog_post => @blog_post, :tag => tag2
    User.count.downto(15) do
      user = User.find(:first, :conditions => ['id != ?', @user.id])
      user.destroy
    end
    get "/admin/blog_posts2"
    assert_response :success
  
    # should show the tags
    assert_match(/(tag2 tag1|tag1 tag2)/, response.body)
  
    # should show the title
    assert_match(/blog post title/, response.body)
    
    # should not show the body
    assert_no_match(/blog post body/, response.body)
    
    # should show a link to the all index page
    assert_match(%r|<a.*href="/admin/blog_posts2\?all=1"|, response.body)
    
    # should not show a sort link for tags
    assert_no_match(%r|<a [^>]*>Tags</a>|, response.body)
    
    # should show a sort link for users
    assert_a_tag_with_get_args(
      'Author', '/admin/blog_posts2',
      {:sort => 'user', :sort_order => 'asc'}, response.body
    )
    
    # should render the author as a username with a link
    assert_select('td') do
      assert_select(
        "a[href=?]", "/admin/users/edit/#{@user.id}", :text => 'soren'
      )
    end
    
    # should say 'Yes' or 'No' for the textile field
    assert_match(/No/, response.body)
    
    # should show a search form with specific fields
    assert_select(
      'form[id=search_form][method=get]', :text => /Title/
    ) do
      assert_select(
        'input[type=radio][name=?][value=all][checked=checked]',
        'search[(all_or_any)]'
      )
      assert_select(
        'input[type=radio][name=?][value=any]', 'search[(all_or_any)]'
      )
      assert_select('input[name=?]', 'search[title]')
      assert_select('input[name=?]', 'search[body]')
      assert_select('select[name=?]', 'search[textile]') do
        assert_select("option[value='']", :text => '')
        assert_select("option[value='true']", :text => 'Yes')
        assert_select("option[value='false']", :text => 'No')
      end
      assert_select('select[name=?]', 'search[user_id]') do
        assert_select("option[value='']", :text => '')
        assert_select("option[value=?]", @user.id)
      end
    end
    
    # should show a link to /admin/comments/new
    assert_select('td') do
      assert_select(
        "a[href=?]",
        "/admin/comments/new?comment%5Bblog_post_id%5D=#{@blog_post.id}",
        :text => "New comment"
      )
    end
    
    # should have a header of 'Blog posts (unpublished)'
    assert_select('h2', :text => 'Blog posts (unpublished)')
    
    # should render custom HTML after the index
    assert_select(
      '#after_index', :text => 'Custom HTML rendered after the index'
    )
    
    # should render custom HTML before the index
    assert_select(
      '#before_index', :text => 'Custom HTML rendered before the index'
    )
    
    # should not have a blank checkbox for the body search field
    assert_select('form[id=search_form][method=get]') do
      assert_select(
        "input[type=checkbox][name=?]", "search[body(blank)]", false
      )
    end
    
    # should output ivar set by index_before_render controller hook
    assert assigns(:var_set_by_before_render_for_index_hook)
    assert_match(/Confirmed that we have some records/, response.body)
  end
  
  def test_index_when_there_is_one_published_post_and_one_unpublished_post
    BlogPost.create! :title => "--unpublished--", :user => @user
    BlogPost.create!(
      :title => "--published--", :published_at => Time.now.utc,
      :user => @user
    )
    get "/admin/blog_posts2"
    assert_response :success
    
    # should show the unpublished post
    assert_match(/--unpublished--/, response.body)
    
    # should not show the published post
    assert_no_match(/--published--/, response.body)
  end
  
  def test_index_when_there_is_1_blog_post_and_16_users
    @blog_post = BlogPost.create! :title => random_word, :user => @user
    User.count.upto(16) do |i|
      User.create! :username => random_word
    end
    get "/admin/blog_posts2"
    
    # should use the autocompleter in the search form for users
    assert_select("select[name=?]", "search[user_id]]", false)
    assert_select(
      "input:not([value])[id=user_autocomplete_input]"
    )
    assert_select(
      "input:not([value])[type=hidden][name=?][id=search_user_id]",
      "search[user_id]"
    )
    assert_select("div[id=user_autocomplete_palette]")
    assert_select('div[id=clear_user_link]')
    assert_match(
      %r|
        new\s*AdminAssistant.RestrictedAutocompleter\(
        \s*"user",
        \s*"search_user_id",
        \s*"/admin/blog_posts2/autocomplete_user",
        [^)]*"includeBlank":\s*true
      |mx,
      response.body
    )
  end
end
