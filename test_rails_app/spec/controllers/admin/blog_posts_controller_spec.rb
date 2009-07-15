require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::BlogPostsController do
  integrate_views
  
  before :all do
    User.destroy_all
    @user = User.create! :username => 'soren'
  end
  
  describe '#autocomplete_user' do
    before :all do
      @bill1 = User.create! :username => 'Bill 1'
      @bill2 = User.create! :username => 'Bill 2'
      1.upto(11) do |i|
        User.create! :username => "Bob #{i}"
      end
      User.create! :username => 'Bob'
    end
    
    describe 'with no matches' do
      before :each do
        get :autocomplete_user, :user_autocomplete_input => 'Jane'
      end

      it 'should return empty results' do
        response.should have_tag('ul')
        response.should_not have_tag('ul > li')
      end
      
      it 'should not render the admin layout' do
        response.should_not have_tag('head > title')
      end
    end
    
    describe 'with two matches' do
      before :each do
        get :autocomplete_user, :user_autocomplete_input => 'Bill'
      end
      
      it 'should return those two matches' do
        response.should have_tag('ul') do
          with_tag "li[id=user#{@bill1.id}]", :text => 'Bill 1'
          with_tag "li[id=user#{@bill2.id}]", :text => 'Bill 2'
        end
      end
    end
    
    describe 'with 12 matches' do
      before :each do
        get :autocomplete_user, :user_autocomplete_input => 'Bob'
      end
      
      it 'should return a max of ten users' do
        response.should have_tag('ul > li', :count => 10)
      end
      
      it 'should make sure the shortest matches are included in the results' do
        response.should have_tag('ul > li', :text => 'Bob')
      end
    end
  end
  
  describe '#create' do
    describe 'when there are no validation errors' do
      before :each do
        title = random_word
        post(
          :create,
          :blog_post => {
            :title => title, :textile => '1', :user_id => @user.id,
            'published_at(1i)' => '', 'published_at(2i)' => '',
            'published_at(3i)' => '', 'published_at(4i)' => '',
            'published_at(5i)' => ''
          }
        )
        @blog_post = BlogPost.find_by_title(title)
      end
      
      it 'should create a new BlogPost' do
        @blog_post.should_not be_nil
        @blog_post.textile?.should be_true
      end
      
      it 'should not set published_at' do
        @blog_post.published_at.should be_nil
      end
    end
    
    describe 'when there are validation errors' do
      before :each do
        post :create, :blog_post => {:title => ''}
      end
      
      it 'should not create a new BlogPost' do
        BlogPost.find_by_title('').should be_nil
      end
      
      it 'should print all the errors' do
        response.should be_success
        response.body.should match(/Title can't be blank/)
      end
      
      it 'should show a link back to the index page' do
        response.should have_tag("a[href=/admin/blog_posts]", 'Back to index')
      end
    end
  end
  
  describe '#destroy' do
    it 'should be an unknown action' do
      lambda { post :destroy, :id => 123 }.should raise_error(
        ActionController::UnknownAction
      )
    end
  end
  
  describe '#edit' do
    before :all do
      @blog_post = BlogPost.create! :title => random_word, :user => @user
    end
    
    before :each do
      get :edit, :id => @blog_post.id
    end
    
    it 'should show a form' do
      response.body.should match(
        %r|<form action="/admin/blog_posts/update/#{@blog_post.id}".*input.*name="blog_post\[title\]"|m
      )
    end
    
    it 'should prefill the values' do
      response.body.should match(%r|input.*value="#{@blog_post.title}"|)
    end
      
    it 'should show a link back to the index page' do
      response.should have_tag("a[href=/admin/blog_posts]", 'Back to index')
    end
  end
  
  describe '#edit when there are more than 15 users' do
    before :all do
      @blog_post = BlogPost.create! :title => random_word, :user => @user
      1.upto(16) do |i|
        User.create! :username => "--user #{i}--"
      end
    end
    
    before :each do
      get :edit, :id => @blog_post.id
    end
    
    it 'should use the restricted autocompleter instead of a drop-down' do
      response.should_not have_tag("select[name=?]", "blog_post[user_id]")
      response.should have_tag(
        "input[id=user_autocomplete_input][value=soren]"
      )
      response.should have_tag(
        "input[type=hidden][name=?][id=blog_post_user_id][value=?]",
        "blog_post[user_id]", @user.id.to_s
      )
      response.should have_tag("div[id=user_autocomplete_palette]")
      response.should have_tag('div[id=clear_user_link]')
      response.body.should match(
        %r|
          new\s*AdminAssistant.RestrictedAutocompleter\(
          \s*"user",
          \s*"blog_post_user_id",
          \s*"/admin/blog_posts/autocomplete_user",
          [^)]*"includeBlank":\s*true
        |mx
      )
    end
  end
  
  describe '#edit when there are less than 15 users' do
    before :all do
      @blog_post = BlogPost.create! :title => random_word, :user => @user
      User.count.downto(14) do
        user = User.find(
          :first, :conditions => ['username != ?', @user.username]
        )
        user.destroy
      end
    end
    
    before :each do
      get :edit, :id => @blog_post.id
    end
    
    it 'should use a drop-down with a blank option' do
      response.should have_tag('select[name=?]', 'blog_post[user_id]') do
        with_tag "option[value='']"
      end
    end
  end

  describe '#index' do 
    describe 'when there are no records' do
      before :all do
        BlogPost.destroy_all
      end
      
      before :each do
        get :index
        response.should be_success
      end
      
      it 'should say "No blog posts found"' do
        response.body.should match(/No blog posts found/)
      end
      
      it "should say the name of the model you're editing" do
        response.body.should match(/Blog posts/)
      end
      
      it 'should have a new link' do
        response.should have_tag(
          "a[href=/admin/blog_posts/new]", 'New blog post'
        )
      end
      
      it 'should have a search form' do
        response.body.should match(
          %r|<a.*onclick="AdminAssistant.show_search_form\(\);.*>Search</a>|
        )
      end
      
      it 'should use the admin layout' do
        response.body.should match(/admin_assistant sample Rails app/)
      end
      
      it 'should use the default admin_assistant CSS' do
        response.should have_tag(
          'link[href^=/stylesheets/admin_assistant_default.css]'
        )
      end
    end

    describe 'when there is one record' do
      before :all do
        BlogPost.destroy_all
        @blog_post = BlogPost.create!(
          :title => "hi there", :user => @user, :textile => false
        )
      end
      
      before :each do
        get :index
        response.should be_success
      end
    
      it 'should show all fields by default' do
        response.body.should match(/hi there/)
      end
      
      it "should say the name of the model you're editing" do
        response.body.should match(/Blog posts/)
      end
      
      it 'should have a new link' do
        response.should have_tag(
          "a[href=/admin/blog_posts/new]", 'New blog post'
        )
      end
      
      it 'should have an edit link' do
        response.should have_tag('td.actions') do
          with_tag "a[href=/admin/blog_posts/edit/#{@blog_post.id}]", 'Edit'
        end
      end
      
      it 'should have a show link' do
        response.should have_tag(
          "a[href=/admin/blog_posts/show/#{@blog_post.id}]", 'Show'
        )
      end
      
      it 'should show sort links' do
        pretty_column_names = {
          'id' => 'ID', 'title' => 'Title', 'created_at' => 'Created at', 
          'updated_at' => 'Updated at', 'body' => 'Body', 'user' => 'User'
        }
        pretty_column_names.each do |field, pretty_column_name|
          assert_a_tag_with_get_args(
            pretty_column_name, '/admin/blog_posts',
            {:sort => field, :sort_order => 'asc'}, response.body
          )
        end
      end
      
      it 'should show pretty column headers' do
        column_headers = [
          'ID', 'Title', 'Created at', 'Updated at', 'Body', 'User'
        ]
        column_headers.each do |column_header|
          response.should have_tag('th') do
            with_tag 'a', column_header
          end
        end
      end
      
      it 'should say how many records are found' do
        response.should have_tag(
          'div.aa_footer', :text => '1 blog post found'
        )
      end
      
      it "should say username because that's one of our default name fields" do
        response.should have_tag('td', :text => 'soren')
      end
      
      it 'should make the textile field an Ajax toggle' do
        toggle_div_id = "blog_post_#{@blog_post.id}_textile"
        post_url =
            "/admin/blog_posts/update/#{@blog_post.id}?" +
            CGI.escape('blog_post[textile]') + "=1&amp;from=#{toggle_div_id}"
        response.should have_tag("div[id=?]", toggle_div_id) do
          ajax_substr = "new Ajax.Updater('#{toggle_div_id}', '#{post_url}'"
          with_tag("a[href=#][onclick*=?]", ajax_substr, :text => 'false')
        end
      end

      it 'should not show the page selector form' do
        response.should have_tag('.pagination') do
          without_tag('form[method=get][action=/admin/blog_posts]')
        end
      end
      
      it 'should have a tbody with the ID blog_posts_index_tbody' do
        response.should have_tag('tbody#blog_posts_index_tbody')
      end
      
      it 'should have a tr with the ID based on @blog_post.id' do
        response.should have_tag("tr[id=blog_post_#{@blog_post.id}]")
      end
    end
    
    describe 'when there is one record that somehow has a nil User' do
      before :all do
        @blog_post = BlogPost.create! :title => "hi there", :user => @user
        BlogPost.update_all "user_id = null"
      end
      
      before :each do
        get :index
      end
      
      it 'should be fine with a nil User' do
        response.should be_success
      end
    end
    
    describe 'when there are more than 10 pages of results' do
      before :all do
        BlogPost.count.upto(251) do
          @blog_post = BlogPost.create!(
            :title => "hi there", :user => @user, :textile => false
          )
        end
      end
      
      before :each do
        get :index
      end
      
      it 'should show the page selector form at the bottom' do
        response.should have_tag('.pagination') do
          with_tag('form[method=get][action=/admin/blog_posts]') do
            with_tag 'input[name=page]'
          end
        end
      end
    end
  end
  
  describe '#index sorting' do
    describe 'when there are two records' do
      before :all do
        BlogPost.destroy_all
        @blog_post1 = BlogPost.create!(
          :title => "title 1", :body => "body 2", :user => @user
        )
        @blog_post2 = BlogPost.create!(
          :title => "title 2", :body => "body 1", :user => @user
        )
      end
      
      describe 'sorted by title asc' do
        before :each do
          get :index, :sort => 'title', :sort_order => 'asc'
          response.should be_success
        end
        
        it 'should sort by title asc' do
          response.body.should match(%r|title 1.*title 2|m)
        end
      
        it 'should show a desc sort link for title' do
          assert_a_tag_with_get_args(
            'Title', '/admin/blog_posts',
            {:sort => 'title', :sort_order => 'desc'}, response.body
          )
        end
        
        it 'should show asc sort links for other fields' do
          pretty_column_names = {
            'id' => 'ID', 'created_at' => 'Created at',
            'updated_at' => 'Updated at', 'body' => 'Body'
          }
          pretty_column_names.each do |field, pretty_column_name|
            assert_a_tag_with_get_args(
              pretty_column_name, '/admin/blog_posts',
              {:sort => field, :sort_order => 'asc'}, response.body
            )
          end
        end
        
        it 'should use the right CSS classes in the title header' do
          response.should have_tag('th[class="sort asc"]') do
            with_tag 'a', :text => 'Title'
          end
        end
        
        it 'should have no CSS sorting classes in the header for ID' do
          response.should have_tag('th:not([class])') do
            with_tag 'a', :text => 'ID'
          end
        end
        
        it 'should mark the title cells with CSS sorting classes' do
          response.should have_tag('td[class="sort"]', :text => 'title 1')
        end
      end
      
      describe 'sorted by title desc' do
        before :each do
          get :index, :sort => 'title', :sort_order => 'desc'
          response.should be_success
        end
        
        it 'should sort by title desc' do
          response.body.should match(%r|title 2.*title 1|m)
        end
      
        it 'should show a no-sort link for title' do
          response.should have_tag("a[href=/admin/blog_posts]", 'Title')
        end
        
        it 'should show asc sort links for other fields' do
          pretty_column_names = {
            'id' => 'ID', 'created_at' => 'Created at',
            'updated_at' => 'Updated at', 'body' => 'Body'
          }
          pretty_column_names.each do |field, pretty_column_name|
            assert_a_tag_with_get_args(
              pretty_column_name, '/admin/blog_posts',
              {:sort => field, :sort_order => 'asc'}, response.body
            )
          end
        end
        
        it 'should use the right CSS classes in the title header' do
          response.should have_tag('th[class="sort desc"]') do
            with_tag 'a', :text => 'Title'
          end
        end
        
        it 'should have no CSS sorting classes in the header for ID' do
          response.should have_tag('th:not([class])') do
            with_tag 'a', :text => 'ID'
          end
        end
        
        it 'should mark the title cells with CSS sorting classes' do
          response.should have_tag('td[class="sort"]', :text => 'title 1')
        end
      end
    end
    
    describe 'by #user, a belongs_to association' do
      before :all do
        BlogPost.destroy_all
        jean_paul = User.create! :username => 'jean-paul'
        BlogPost.create!(
          :title => 'title 1', :body => 'body 1', :user => @user
        )
        BlogPost.create!(
          :title => 'title 2', :body => 'body 2', :user => jean_paul
        )
      end
      
      describe 'asc' do
        before :each do
          get :index, :sort => 'user', :sort_order => 'asc'
          response.should be_success
        end
        
        it "should show jean-paul's blog post before soren's" do
          response.body.should match(%r|jean-paul.*soren|m)
        end
        
        it 'should use the right CSS classes in the user header' do
          response.should have_tag('th[class="sort asc"]') do
            with_tag 'a', :text => 'User'
          end
        end
        
        it 'should mark the title cells with CSS sorting classes' do
          response.should have_tag('td[class="sort"]', :text => 'jean-paul')
        end
      
        it 'should show a desc sort link for user' do
          assert_a_tag_with_get_args(
            'User', '/admin/blog_posts',
            {:sort => 'user', :sort_order => 'desc'}, response.body
          )
        end
      end
      
      describe 'desc' do
        before :each do
          get :index, :sort => 'user', :sort_order => 'desc'
          response.should be_success
        end
        
        it "should show soren's blog post before jean-paul's" do
          response.body.should match(%r|soren.*jean-paul|m)
        end
      end
    end
  end
  
  describe '#index search' do
    before :all do
      BlogPost.destroy_all
    end
    
    before :each do
      get :index, :search => 'foo'
      response.should be_success
    end
    
    describe 'when there are no records' do
      it "should say 'No blog posts found'" do
        response.body.should match(/No blog posts found/)
      end
      
      it "should display the search with the terms" do
        response.body.should match(
          %r|<form[^>]*id="search_form".*show_search_form\(\)|m
        )
        response.body.should match(%r|input.*value="foo"|)
      end
      
      it 'should show a link back to the index page' do
        response.should have_tag("a[href=/admin/blog_posts]", 'Back to index')
      end
    end
    
    describe 'when there are no records that match' do
      before :all do
        BlogPost.create!(
          :title => 'no match', :body => 'no match', :user => @user
        )
      end
      
      it "should say 'No blog posts found'" do
        response.body.should match(/No blog posts found/)
      end
    end
    
    describe 'when there is a blog post with a matching title' do
      before :all do
        BlogPost.create!(
          :title => 'foozy', :body => 'blog post body', :user => @user
        )
      end
      
      it "should show that blog post" do
        response.body.should match(/blog post body/)
      end
    end
    
    describe 'when there is a blog post with a matching body' do
      before :all do
        BlogPost.create!(
          :title => 'blog post title', :body => 'barfoo', :user => @user
        )
      end
      
      it "should show that blog post" do
        response.body.should match(/blog post title/)
      end
      
      it 'should say how many records are found' do
        response.body.should match(/1 blog post found/)
      end
    end
  end
  
  describe '#index pagination with 51 records' do
    before :all do
      BlogPost.destroy_all
      1.upto(51) do |i|
        BlogPost.create!(
          :title => "title -#{i}-", :body => "body -#{i}-", :user => @user
        )
      end
    end
    
    describe 'when looking at the first page' do
      before :each do
        get :index
        response.should be_success
      end
      
      it 'should have a link to the next page' do
        response.should have_tag(
          "a[href=/admin/blog_posts?page=2]", 'Next &raquo;'
        )
        response.should have_tag("a[href=/admin/blog_posts?page=2]", '2')
      end
      
      it 'should not have a link to the previous page' do
        response.should_not have_tag(
          "a[href=/admin/blog_posts?page=0]", '&laquo; Previous'
        )
        response.should_not have_tag("a[href=/admin/blog_posts?page=0]", '0')
      end
      
      it 'should the full number of posts found' do
        response.body.should match(/51 blog posts found/)
      end
    end
    
    describe 'when looking at the second page' do
      before :each do
        get :index, :page => '2'
        response.should be_success
      end
      
      it 'should have a link to the next page' do
        response.should have_tag(
          "a[href=/admin/blog_posts?page=3]", 'Next &raquo;'
        )
        response.should have_tag("a[href=/admin/blog_posts?page=3]", '3')
      end
      
      it 'should have a link to the previous page' do
        response.should have_tag(
          "a[href=/admin/blog_posts?page=1]", '&laquo; Previous'
        )
        response.should have_tag("a[href=/admin/blog_posts?page=1]", '1')
      end
      
      it 'should the full number of posts found' do
        response.body.should match(/51 blog posts found/)
      end
    end
    
    describe 'when looking at the third page' do
      before :each do
        get :index, :page => '3'
        response.should be_success
      end

      it 'should not have a link to the next page' do
        response.should_not have_tag(
          "a[href=/admin/blog_posts?page=4]", 'Next &raquo;'
        )
        response.should_not have_tag("a[href=/admin/blog_posts?page=3]", '3')
      end
      
      it 'should have a link to the previous page' do
        response.should have_tag(
          "a[href=/admin/blog_posts?page=2]", '&laquo; Previous'
        )
        response.should have_tag("a[href=/admin/blog_posts?page=2]", '2')
      end
      
      it 'should the full number of posts found' do
        response.body.should match(/51 blog posts found/)
      end
    end
  end
  
  describe '#new' do
    before :each do
      @alfie = User.create! :username => 'alfie'
      get :new
    end
    
    it 'should show a form' do
      response.body.should match(
        %r|<form action="/admin/blog_posts/create".*input.*name="blog_post\[title\]"|m
      )
    end
    
    it 'should use a textarea for the body field' do
      response.body.should match(
        %r|<textarea.*name="blog_post\[body\]".*>.*</textarea>|
      )
    end
      
    it 'should show a link back to the index page' do
      response.should have_tag("a[href=/admin/blog_posts]", 'Back to index')
    end
      
    it 'should show pretty field names' do
      field_names = ['Title', 'Body']
      field_names.each do |field_name|
        response.should have_tag('label', field_name)
      end
    end
    
    it "should use a checkbox for the boolean field 'textile'" do
      response.body.should match(
        %r!
          <input[^>]*
          (name="blog_post\[textile\][^>]*type="checkbox"|
           type="checkbox"[^>]*name="blog_post\[textile\])
        !x
      )
    end
    
    it 'should use a drop-down for the user field' do
      response.should have_tag("select[name=?]", "blog_post[user_id]") do
        with_tag "option:nth-child(1)[value='']"
        with_tag "option:nth-child(2)[value=?]", @alfie.id, :text => 'alfie'
        with_tag "option:nth-child(3)[value=?]", @user.id, :text => 'soren'
      end
    end
    
    it 'should set the controller path as a CSS class' do
      response.should have_tag("div[class~=admin_blog_posts]")
    end
    
    it 'should use dropdowns with nil defaults for published_at' do
      nums_and_dt_fields = {
        1 => :year, 2 => :month, 3 => :day, 4 => :hour, 5 => :min
      }
      nums_and_dt_fields.each do |num, dt_field|
        name = "blog_post[published_at(#{num}i)]"
        value_for_now_option = Time.now.send(dt_field).to_s
        if [:hour, :min].include?(dt_field) && value_for_now_option.size == 1
          value_for_now_option = "0#{value_for_now_option}"
        end
        response.should have_tag('select[name=?]', name) do
          with_tag "option[value='']"
          with_tag "option:not([selected])[value=?]", value_for_now_option
        end
      end
    end
    
    it 'should show a nilify link for published_at' do
      response.body.should have_tag(
        'a', :text => "Set \"published at\" to nil"
      )
    end
  end
  
  describe '#new with a preset value in the GET arguments' do
    before :each do
      get :new, :blog_post => {:user_id => @user.id.to_s}
    end
    
    it 'should set that preselected value' do
      response.should have_tag("select[name=?]", "blog_post[user_id]") do
        with_tag "option[value=?][selected=selected]",
                 @user.id, :text => 'soren'
        with_tag "option[value='']"
      end
    end
  end
  
  describe '#new when there are more than 15 users' do
    before :all do
      User.destroy_all
      1.upto(16) do |i|
        User.create! :username => "--user #{i}--"
      end
    end
    
    before :each do
      get :new
    end
    
    it 'should use the restricted autocompleter instead of a drop-down' do
      response.should_not have_tag("select[name=?]", "blog_post[user_id]")
      response.should have_tag("input[id=user_autocomplete_input]")
      response.should have_tag(
        "input[type=hidden][name=?][id=blog_post_user_id]",
        "blog_post[user_id]"
      )
      response.should have_tag("div[id=user_autocomplete_palette]")
      response.should have_tag('div[id=clear_user_link]')
      response.body.should match(
        %r|
          new\s*AdminAssistant.RestrictedAutocompleter\(
          \s*"user",
          \s*"blog_post_user_id",
          \s*"/admin/blog_posts/autocomplete_user",
          [^)]*"includeBlank":\s*true
        |mx
      )
    end
  end
  
  describe '#show' do
    before :all do
      BlogPost.destroy_all
      @blog_post = BlogPost.create!(
        :title => "foo > bar & baz", :user => @user, :textile => false
      )
    end
    
    before :each do
      get :show, :id => @blog_post.id
    end
    
    it 'should show the HTML-escaped title' do
      response.body.should match(/foo &gt; bar &amp; baz/)
    end
    
    it 'should have a link to edit' do
      response.should have_tag(
        "a[href=/admin/blog_posts/edit/#{@blog_post.id}]", 'Edit'
      )
    end
    
    it 'should show soren' do
      response.body.should match(/soren/)
    end
  end
  
  describe '#update' do
    before :all do
      @blog_post = BlogPost.create! :title => random_word, :user => @user
    end
    
    describe 'when there are no validation errors' do
      before :each do
        title2 = random_word
        post(
          :update,
          :id => @blog_post.id,
          :blog_post => {
            :title => title2, 'published_at(1i)' => '2009',
            'published_at(2i)' => '1', 'published_at(3i)' => '2',
            'published_at(4i)' => '3', 'published_at(5i)' => '4'
          }
        )
        response.should redirect_to(:action => 'index')
        @blog_post_prime = BlogPost.find_by_title(title2)
      end
      
      it 'should update a pre-existing BlogPost' do
        @blog_post_prime.should_not be_nil
      end
      
      it 'should set published_at' do
        @blog_post_prime.published_at.should == Time.utc(2009, 1, 2, 3, 4)
      end
    end
    
    describe 'when there are validation errors' do
      before :each do
        post :update, :id => @blog_post.id, :blog_post => {:title => ''}
      end
      
      it 'should not create a new BlogPost' do
        BlogPost.find_by_title('').should be_nil
      end
      
      it 'should print all the errors' do
        response.should be_success
        response.body.should match(/Title can't be blank/)
      end
      
      it 'should show a link back to the index page' do
        response.should have_tag("a[href=/admin/blog_posts]", 'Back to index')
      end
    end
  end
  
  describe '#update as Ajax toggle' do
    before :all do
      @blog_post = BlogPost.create!(
        :title => random_word, :user => @user, :textile => false
      )
    end
    
    before :each do
      post(
        :update,
        :id => @blog_post.id, :from => "blog_post_#{@blog_post.id}_textile",
        :blog_post => {:textile => '1'}
      )
    end
    
    it 'should return success' do
      response.should be_success
    end
    
    it 'should update the textile field' do
      @blog_post.reload.textile.should be_true
    end
    
    it 'should only render a small snippet of HTML with Ajax in it' do
      toggle_div_id = "blog_post_#{@blog_post.id}_textile"
      post_url =
          "/admin/blog_posts/update/#{@blog_post.id}?" +
          CGI.escape('blog_post[textile]') + "=0&amp;from=#{toggle_div_id}"
      response.should_not have_tag('div[id=?]', toggle_div_id)
      ajax_substr = "new Ajax.Updater('#{toggle_div_id}', '#{post_url}'"
      response.should have_tag(
        "a[href=#][onclick*=?]", ajax_substr, :text => 'true'
      )
      response.should_not have_tag('title', :text => 'Admin')
    end
  end
end
