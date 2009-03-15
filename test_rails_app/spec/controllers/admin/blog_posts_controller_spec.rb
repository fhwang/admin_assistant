require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::BlogPostsController do
  integrate_views
  
  before :all do
    User.destroy_all
    @user = User.create! :username => 'soren'
  end
  
  describe '#create' do
    describe 'when there are no validation errors' do
      it 'should create a new BlogPost' do
        title = random_word
        post(
          :create,
          :blog_post => {
            :title => title, :textile => '1', :user_id => @user.id
          }
        )
        blog_post = BlogPost.find_by_title(title)
        blog_post.should_not be_nil
        blog_post.textile?.should be_true
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
        response.body.should match(/Blog Posts/)
      end
      
      it 'should have a new link' do
        response.should have_tag(
          "a[href=/admin/blog_posts/new]", 'New blog post'
        )
      end
      
      it 'should have a search form' do
        response.body.should match(
          %r|<a.*onclick="show_search_form\(\);.*>Search</a>|
        )
      end
      
      it 'should use the admin layout' do
        response.body.should match(/admin_assistant sample Rails app/)
      end
    end

    describe 'when there is one record' do
      before :all do
        BlogPost.destroy_all
        @blog_post = BlogPost.create! :title => "hi there", :user => @user
      end
      
      before :each do
        get :index
        response.should be_success
      end
    
      it 'should show all fields by default' do
        response.body.should match(/hi there/)
      end
      
      it "should say the name of the model you're editing" do
        response.body.should match(/Blog Posts/)
      end
      
      it 'should have a new link' do
        response.should have_tag(
          "a[href=/admin/blog_posts/new]", 'New blog post'
        )
      end
      
      it 'should have an edit link' do
        response.should have_tag(
          "a[href=/admin/blog_posts/edit/#{@blog_post.id}]", 'Edit'
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
        response.body.should match(/1 blog post found/)
      end
      
      it "should say username because that's one of our default name fields" do
        response.should have_tag('td', :text => 'soren')
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
        with_tag "option[value=?]", @user.id, :text => 'soren'
      end
      response.should_not have_tag("option[value='']")
    end
    
    it 'should set the controller path as a CSS class' do
      response.should have_tag("div[class~=admin_blog_posts]")
    end
  end
  
  describe '#update' do
    before :all do
      @blog_post = BlogPost.create! :title => random_word, :user => @user
    end
    
    describe 'when there are no validation errors' do
      it 'should update a pre-existing BlogPost' do
        title2 = random_word
        post :update, :id => @blog_post.id, :blog_post => {:title => title2}
        response.should redirect_to(:action => 'index')
        BlogPost.find_by_title(title2).should_not be_nil
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
end
