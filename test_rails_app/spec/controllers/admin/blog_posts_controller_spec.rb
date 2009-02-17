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
        BlogPost.create! :title => "hi there"
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
end
