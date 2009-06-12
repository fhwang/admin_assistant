require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::BlogPostsReadOnlyController do
  integrate_views

  before :all do
    User.destroy_all
    @user = User.create! :username => 'soren'
  end
  
  describe '#index' do
    before :all do
      BlogPost.destroy_all
      @blog_post = BlogPost.create!(
        :title => "hi there", :user => @user, :textile => false
      )
    end

    before :each do
      get :index
    end
    
    it 'should be successful' do
      response.should be_success
    end
    
    it 'should not have a new link' do
      response.should_not have_tag('a', :text => 'New blog post')
    end
    
    it 'should not make the textile field an Ajax toggle' do
      response.should_not have_tag(
        "div[id=?]", "blog_post_#{@blog_post.id}_textile"
      )
    end
  end
end
