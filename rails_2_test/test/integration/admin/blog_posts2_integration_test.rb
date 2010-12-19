require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class Admin::BlogPosts2IntegrationTest < ActionController::IntegrationTest
  def setup
    User.destroy_all
    @user = User.find_or_create_by_username 'soren'
  end
  
  def create_foobar_blog_posts
    BlogPost.destroy_all
    BlogPost.create!(
      :title => 'textile_false_foobar', :textile => false, :user => @user
    )
    BlogPost.create!(
      :title => 'textile_true_foobar', :textile => true, :user => @user
    )
    BlogPost.create!(
      :title => 'not_in_the_title', :textile => false,
      :body => 'foobar here though', :user => @user
    )
    BlogPost.create!(
      :title => 'textile is false', :textile => false,
      :body => "body doesn't say f**bar", :user => @user
    )
    BlogPost.create!(
      :title => 'already published', :textile => false,
      :body => "body doesn't say f**bar", :user => @user,
      :published_at => Time.now.utc
    )
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
      "/admin/blog_posts2/edit/#{@blog_post.id}?preview=1"
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
  
  def test_index_all_1
    BlogPost.create!(
      :title => "--published--", :published_at => Time.now.utc,
      :user => @user
    )
    get "/admin/blog_posts2", :all => '1'
    assert_response :success

    # should show published posts
    assert_match(/--published--/, response.body)
    
    # should show a sort link for titles that includes all=1
    assert_a_tag_with_get_args(
      'Title', '/admin/blog_posts2',
      {:sort => 'title', :sort_order => 'asc', :all => '1'}, response.body
    )
      
    # should have a header of 'Blog posts (all)'
    assert_select('h2', :text => 'Blog posts (all)')
  end
  
  def test_index_all_1_with_two_published_posts
    BlogPost.create!(
      :title => 'published later', :published_at => Time.utc(2009, 2, 1),
      :user => @user
    )
    BlogPost.create!(
      :title => 'published earlier', :published_at => Time.utc(2009, 1, 1),
      :user => @user
    )
    get "/admin/blog_posts2", :all => '1'
    
    # should order by published_at desc
    assert_match(/published later.*published earlier/m, response.body)
  end
  
  def test_index_when_searching_for_title_with_foobar
    create_foobar_blog_posts
    get(
      "/admin/blog_posts2",
      :search => {
        :body => "", :title => "foobar", :textile => "", :id => "",
        :user => ''
      }
    )
    assert_response :success
    
    # should match records where textile=true
    assert_select('td', :text => 'textile_true_foobar')
    
    # should match records where textile=false
    assert_select('td', :text => 'textile_false_foobar')
      
    # should show the textile and title search fields pre-set
    assert_select('form[id=search_form][method=get]') do
      assert_select('input[name=?][value=foobar]', 'search[title]')
      assert_select('select[name=?]', 'search[textile]') do
        assert_select("option[value=''][selected=selected]", :text => '')
        assert_select("option[value='true']", :text => 'Yes')
        assert_select("option[value='false']", :text => 'No')
      end
    end
  end
  
  def test_index_when_searching_for_title_with_foobar_and_textile_false
    create_foobar_blog_posts
    get(
      "/admin/blog_posts2",
      :search => {
        :textile => 'false', :title => 'foobar', '(all_or_any)' => 'all',
        :user => ''
      }
    )
    assert_response :success
  
    # should show blog posts with textile=false and the word 'foobar' in the title
    assert_select('td', :text => 'textile_false_foobar')
  
    # should not show a blog post with textile=true
    assert_no_match(%r|<td[^>]*>textile_true_foobar</td>|, response.body)
  
    # should not show a blog post just 'cause it has 'foobar' in the body
    assert_no_match(%r|<td[^>]*>not_in_the_title</td>|, response.body)
    
    # should show the textile, title, and all-or-any search fields pre-set
    assert_select('form[id=search_form][method=get]') do
      assert_select(
        'input[type=radio][name=?][value=all][checked=checked]',
        'search[(all_or_any)]'
      )
      assert_select('input[name=?][value=foobar]', 'search[title]')
      assert_select('select[name=?]', 'search[textile]') do
        assert_select("option[value='']", :text => '')
        assert_select("option[value='true']", :text => 'Yes')
        assert_select("option[value='false'][selected=selected]", :text => 'No')
      end
    end
  end
  
  def test_index_for_title_with_foobar_and_textile_false
    create_foobar_blog_posts
    get(
      "/admin/blog_posts2",
      :search => {
        :textile => 'false', :title => 'foobar', '(all_or_any)' => 'any',
        :user => ''
      }
    )
    assert_response :success
      
    # should show a blog post with 'foobar' in the title
    assert_select('td', :text => 'textile_true_foobar')
    
    # should show a blog post with textile=false
    assert_select('td', :text => 'textile is false')
    
    # should not show a blog post that's already published, because of the conditions set in controller
    assert_no_match(%r|<td[^>]*>already published</td>|, response.body)
    
    # should show the textile, title, and all-or-any search fields pre-set
    assert_select('form[id=search_form][method=get]') do
      assert_select(
        'input[type=radio][name=?][value=any][checked=checked]',
        'search[(all_or_any)]'
      )
      assert_select('input[name=?][value=foobar]', 'search[title]')
      assert_select('select[name=?]', 'search[textile]') do
        assert_select("option[value='']", :text => '')
        assert_select("option[value='true']", :text => 'Yes')
        assert_select("option[value='false'][selected=selected]", :text => 'No')
      end
    end
  end
  
  def test_index_when_searching_by_user_and_there_are_less_than_15_users
    @user2 = User.create! :username => 'Jean-Paul'
    User.count.downto(14) do
      user = User.find(
        :first,
        :conditions => [
          'username != ? and username != ?', @user.username, @user.username
        ]
      )
      user.destroy
    end
    BlogPost.destroy_all
    BlogPost.create! :title => "Soren's first post", :user => @user
    BlogPost.create! :title => "Soren's second post", :user => @user
    BlogPost.create! :title => "Jean-Paul's post", :user => @user2
    get(
      "/admin/blog_posts2",
      :search => {:textile => '', :title => '', :user_id => @user2.id.to_s}
    )
    assert_response :success
    
    # should show blog posts by Jean-Paul
    assert_select('td', :text => "Jean-Paul's post")
    
    # should not show blog posts by Soren
    assert_no_match(%r|<td[^>]*>Soren's first post</td>|, response.body)
    assert_no_match(%r|<td[^>]*>Soren's second post</td>|, response.body)
    
    # should show the user field pre-set
    assert_select(
      'form[id=search_form][method=get]', :text => /Title/
    ) do
      assert_select('select[name=?]', 'search[user_id]') do
        assert_select("option[value='']", :text => '')
        assert_select("option[value=?][selected=selected]", @user2.id)
      end
    end
  end
  
  def test_index_when_searching_by_user_and_there_are_more_than_15_users
    @blog_post = BlogPost.create! :title => random_word, :user => @user
    User.count.upto(16) do |i|
      User.create! :username => "--user #{i}--"
    end
    get(
      "/admin/blog_posts2",
      :search => {:textile => '', :title => '', :user_id => @user.id.to_s}
    )
    assert_response :success
    
    # should show pre-populated user autocomplete in the search form
    assert_select("select[name=?]", "search[user_id]]", false)
    assert_select(
      "input[id=user_autocomplete_input][value=?]", @user.username
    )
    assert_select(
      "input[type=hidden][name=?][id=search_user_id][value=?]",
      "search[user_id]", @user.id.to_s
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
  
  def test_index_with_a_blank_search
    get(
      "/admin/blog_posts2",
      :search => {
        :body => '', :title => '', :textile => '', :id => '', :user_id => '',
        '(all_or_any)' => 'all', 'id(comparator)' => ''
      }
    )
    
    # should be successful
    assert_response :success
  end
  
  def test_index_with_one_record_with_a_false_textile_field
    BlogPost.destroy_all
    @blog_post = BlogPost.create!(
      :title => random_word, :user => @user, :textile => false
    )
    get "/admin/blog_posts2"
      
    # should make the textile field an Ajax toggle
    toggle_div_id = "blog_post_#{@blog_post.id}_textile"
    post_url =
        "/admin/blog_posts2/update/#{@blog_post.id}?" +
        CGI.escape('blog_post[textile]') + "=1&amp;from=#{toggle_div_id}"
    assert_select("div[id=?]", toggle_div_id) do
      ajax_substr = "new Ajax.Updater('#{toggle_div_id}', '#{post_url}'"
      assert_select("a[href=#][onclick*=?]", ajax_substr, :text => 'No')
    end
  end
  
  def test_index_with_11_blog_posts
    BlogPost.destroy_all
    1.upto(11) do |i|
      BlogPost.create!(
        :title => "--post #{i}--", :user => @user
      )
    end
    get "/admin/blog_posts2"
    
    # should show link to page 2
    assert_select("a[href=/admin/blog_posts2?page=2]")
    
    # should say 11 blog posts found
    assert_match(/11 blog posts found/, response.body)

    # should mark the table rows with custom CSS class
    assert_select('tr[class~="custom_tr_css_class"]')

    # should mark the user cells with custom CSS class
    assert_select('td[class~="custom_td_css_class"]', :text => @user.username)
  end
  
  def test_new
    Tag.find_or_create_by_tag 'tag_from_yesterday'
    get "/admin/blog_posts2/new"
    
    # should show a field for tags
    assert_match(%r|<input.*name="blog_post\[tags\]"|m, response.body)
    
    # should show current tags
    assert_match(/tag_from_yesterday/, response.body)
    
    # should show a checkbox for the 'publish' virtual field
    if %w(2.3.2 2.3.3 2.3.4).include?(RAILS_GEM_VERSION)
      assert_match(
        %r!
          <input[^>]*
          (name="blog_post\[publish\][^>]*type="hidden"[^>]value="0"|
          type="hidden"[^>]*name="blog_post\[publish\][^>]value="0")
          .*
          <input[^>]*
          (name="blog_post\[publish\][^>]*type="checkbox"[^>]value="1"|
           type="checkbox"[^>]*name="blog_post\[publish\][^>]value="1")
        !x,
        response.body
      )
    elsif %w(2.1.0 2.1.2 2.2.2).include?(RAILS_GEM_VERSION)
      assert_match(
        %r!
          <input[^>]*
          (name="blog_post\[publish\][^>]*type="checkbox"[^>]value="1"|
           type="checkbox"[^>]*name="blog_post\[publish\][^>]value="1")
          .*
          <input[^>]*
          (name="blog_post\[publish\][^>]*type="hidden"[^>]value="0"|
          type="hidden"[^>]*name="blog_post\[publish\][^>]value="0")
        !x,
        response.body
      )
    else
      raise "I don't have a specified behavior for #{RAILS_GEM_VERSION}"
    end
    
    # should not duplicate the DOM ID of the 'publish' checkbox on the page
    assert_equal(
      1,
      response.body.scan(
        /id="blog_post_publish"|id="blog_post\[publish\]"/
      ).size
    )
    
    # should show the description for the 'publish' virtual field
    assert_match(
      /Click this and published_at will be set automatically/,
      response.body
    )
    
    # should show a preview button
    assert_select('input[type=submit][value=Preview]')
    
    # should use a textarea for the body field
    assert_select(
      'textarea[name=?][cols=20][rows=40]', 'blog_post[body]'
    )
    
    # should use a checkbox for the boolean field 'textile'
    assert_match(
      %r!
        <input[^>]*
        (name="blog_post\[textile\][^>]*type="checkbox"|
         type="checkbox"[^>]*name="blog_post\[textile\])
      !x,
      response.body
    )
    
    # should say 'Author' instead of 'User'
    assert_match(/Author/, response.body)
  end
  
  def test_show
    @blog_post = BlogPost.create! :title => random_word, :user => @user
    get "/admin/blog_posts2/show/#{@blog_post.id}"
    assert_response :success

    # should show user
    assert_match(/soren/, response.body)
    
    # should not show created at
    assert_no_match(/Created at/, response.body)
  end
  
  def test_update_when_there_are_no_validation_errors
    @blog_post = BlogPost.create! :title => random_word, :user => @user
    post(
      "/admin/blog_posts2/update/#{@blog_post.id}",
      :blog_post => {:tags => 'tag1 tag2 tag3'}
    )
    
    # should set the tags_string
    @blog_post.reload
    assert_match(/tag1,tag2,tag3/, @blog_post.tags_string)
  end
  
  def test_update_when_the_user_has_clicked_Preview
    @blog_post = BlogPost.create! :title => random_word, :user => @user
    title2 = random_word
    post(
      "/admin/blog_posts2/update/#{@blog_post.id}",
      :blog_post => {:title => title2},
      :commit => 'Preview'
    )
      
    # should redirect to the edit page with the preview flag
    assert_redirected_to("/admin/blog_posts2/edit/#{@blog_post.id}?preview=1")
  end
  
  def test_update_with_a_bad_tag
    @blog_post = BlogPost.create! :title => random_word, :user => @user
    post(
      "/admin/blog_posts2/update/#{@blog_post.id}",
      :blog_post => {:tags => "foo bar! baz"}
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
  
  def test_update_with_a_bad_tag_and_a_missing_title
    @blog_post = BlogPost.create! :title => random_word, :user => @user
    post(
      "/admin/blog_posts2/update/#{@blog_post.id}",
      :blog_post => {:tags => "foo bar! baz", :title => ''}
    )
    
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
end
