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
    
    it 'should have a show link' do
      response.should have_tag(
        "a[href=/admin/blog_posts_read_only/show/#{@blog_post.id}]", 'Show'
      )
    end
  end
  
  describe '#show for a published blog post' do
    before :all do
      @blog_post = BlogPost.create!(
        :title => 'published', :user => @user, :published_at => Time.now.utc
      )
    end
    
    before :each do
      get :show, :id => @blog_post.id
    end
    
    it 'should not show textile' do
      response.body.should_not match(/Textile/)
    end
    
    it 'should use the block for the title' do
      response.should have_tag(
        'h2', :text => "Published blog post #{@blog_post.id}"
      )
    end
  end
  
  describe '#show for an unpublished blog post' do
    before :all do
      @blog_post = BlogPost.create!(
        :title => 'unpublished', :user_id => @user.id, :published_at => nil
      )
    end
    
    before :each do
      get :show, :id => @blog_post.id
    end
    
    it 'should use the block for the title' do
      response.should have_tag(
        'h2', :text => "Unpublished blog post #{@blog_post.id}"
      )
    end
  end
end
