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
  end
  
  describe '#new' do
    it 'should show a form' do
      get :new
      response.body.should match(
        %r|<form action="/admin/blog_posts/create".*input.*name="blog_post\[title\]"|m
      )
    end
  end
  
  describe '#update' do
    describe 'when there are no validation errors' do
      before :all do
        @blog_post = BlogPost.create! :title => random_word
      end
      
      it 'should update a pre-existing BlogPost' do
        title2 = random_word
        post :update, :id => @blog_post.id, :blog_post => {:title => title2}
        response.should be_redirect
        BlogPost.find_by_title(title2).should_not be_nil
      end
    end
  end
end
