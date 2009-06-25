require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::Comments2Controller do
  integrate_views
  
  before :all do
    @user = User.find_or_create_by_username 'soren'
    @published_blog_post = BlogPost.create!(
      :title => 'published', :user => @user, :published_at => Time.now.utc
    )
    @unpublished_blog_post = BlogPost.create!(
      :title => 'unpublished', :user => @user, :published_at => nil
    )
  end
  
  describe '#edit' do
    before :all do
      @comment = Comment.create!(
        :comment => "you're funny but I'm funnier",
        :blog_post => @published_blog_post
      )
    end
    
    before :each do
      get :edit, :id => @comment.id
    end
    
    it 'should not have a textarea for Comment#comment' do
      response.should_not have_tag("textarea[name=?]", "comment[comment]")
    end
  end
  
  describe '#index' do
    before :all do
      Comment.destroy_all
      @comment_on_published = Comment.create!(
        :comment => "this is published",
        :blog_post => @published_blog_post
      )
      @comment_on_unpublished = Comment.create!(
        :comment => "this was published but no more",
        :blog_post => @unpublished_blog_post
      )
    end
    
    before :each do
      get :index
    end
    
    it 'should show a comment on a published blog post' do
      response.should have_tag('td', :text => 'this is published')
    end

    it 'should not show a comment on an unpublished blog post' do
      response.should_not have_tag(
        'td', :text => 'this was published but no more'
      )
    end
  end

  describe '#new' do
    before :each do
      get :new
    end
    
    it 'should have a textarea for Comment#comment' do
      response.should have_tag("textarea[name=?]", "comment[comment]")
    end
  end
end
