require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::BlogPostsController do
  integrate_views
  
  describe '#create' do
    describe 'when there are no validation errors' do
      it 'should create a new BlogPost' do
        title = random_word
        post :create, :blog_post => {:title => title}
        BlogPost.find_by_title(title).should_not be_nil
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
      @blog_post = BlogPost.create! :title => random_word
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
      
      it 'should say "No records"' do
        response.body.should match(/No records/)
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
        response.body.should match(/ADMIN LAYOUT/)
      end
    end

    describe 'when there is one record' do
      before :all do
        @blog_post = BlogPost.create! :title => "hi there"
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
    end
    
    describe 'when there are two records' do
      before :all do
        @blog_post1 = BlogPost.create! :title => "title 1", :body => "body 2"
        @blog_post2 = BlogPost.create! :title => "title 2", :body => "body 1"
      end
      
      before :each do
        get :index
        response.should be_success
      end
      
      it 'should show sort links' do
        %w(id title created_at updated_at body).each do |field|
          assert_a_tag_with_get_args(
            field, '/admin/blog_posts', {:sort => field, :sort_order => 'asc'},
            response.body
          )
        end
      end
    end
  end
  
  describe '#index search' do
    before :all do
      BlogPost.destroy_all
    end
    
    before :each do
      get :index, :search => {:terms => 'foo'}
      response.should be_success
    end
    
    describe 'when there are no records' do
      it "should say 'No records'" do
        response.body.should match(/No records/)
      end
      
      it "should display the search with the terms" do
        response.body.should match(
          %r|<div id="search_form".*show_search_form\(\)|m
        )
        response.body.should match(%r|input.*value="foo"|)
      end
      
      it 'should show a link back to the index page' do
        response.should have_tag("a[href=/admin/blog_posts]", 'Back to index')
      end
    end
    
    describe 'when there are no records that match' do
      before :all do
        BlogPost.create! :title => 'no match', :body => 'no match'
      end
      
      it "should say 'No records'" do
        response.body.should match(/No records/)
      end
    end
    
    describe 'when there is a blog post with a matching title' do
      before :all do
        BlogPost.create! :title => 'foozy', :body => 'blog post body'
      end
      
      it "should show that blog post" do
        response.body.should match(/blog post body/)
      end
    end
    
    describe 'when there is a blog post with a matching body' do
      before :all do
        BlogPost.create! :title => 'blog post title', :body => 'barfoo'
      end
      
      it "should show that blog post" do
        response.body.should match(/blog post title/)
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
  end
  
  describe '#update' do
    before :all do
      @blog_post = BlogPost.create! :title => random_word
    end
    
    describe 'when there are no validation errors' do
      it 'should update a pre-existing BlogPost' do
        title2 = random_word
        post :update, :id => @blog_post.id, :blog_post => {:title => title2}
        response.should be_redirect
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
