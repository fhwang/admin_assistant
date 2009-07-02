require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::BlogPostsCustomNewAndEditController do
  integrate_views
  
  before :all do
    User.destroy_all
    @user = User.create! :username => 'soren'
  end
  
  describe '#index with one blog post' do
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
    
    it 'should have a new link' do
      response.should have_tag(
        "a[href=/admin/blog_posts_custom_new_and_edit/new]", 'New blog post'
      )
    end
      
    it 'should have an edit link' do
      response.should have_tag('td.actions') do
        with_tag(
          "a[href=/admin/blog_posts_custom_new_and_edit/edit/#{@blog_post.id}]",
          'Edit'
        )
      end
    end
  end
end
