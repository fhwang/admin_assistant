require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::BlogPosts3Controller do
  integrate_views
  
  before :all do
    User.destroy_all
    @user = User.create! :username => 'soren', :password => 'password'
  end
  
  describe '#index when the blank-body count has been cached in memcache but the request is looking for the default index' do
    before :all do
      $cache.flush
      another_key = 
          "AdminAssistant::Admin::BlogPosts3Controller_count__body_is_null_or_body______"
      $cache.write another_key, 1_000_000, :expires_in => 12.hours
    end
    
    before :each do
      get :index
    end
    
    it 'should not read a value from memcache' do
      response.body.should_not match(/1000000 posts found/)
    end

    it 'should set the count in memcache' do
      key =
          "AdminAssistant::Admin::BlogPosts3Controller_count_published_at_is_null_"
      $cache.read(key).should_not be_nil
      $cache.expires_in(key).should be_close(12.hours, 5.seconds)
    end
  end
  
  describe '#index when the count has been cached in memcache' do
    before :all do
      key =
          "AdminAssistant::Admin::BlogPosts3Controller_count_published_at_is_null_"
      $cache.write key, 1_000_000, :expires_in => 12.hours
    end
    
    before :each do
      $cache.raise_on_write
      get :index
    end
    
    it 'should read memcache and not hit the database' do
      response.body.should match(/1000000 posts found/)
    end
  end
  
  describe "#index with more than one page's worth of unpublished blog posts" do
    before :all do
      $cache.flush
      BlogPost.destroy_all
      1.upto(26) do |i|
        BlogPost.create!(
          :title => "unpublished blog post #{i}", :user => @user,
          :published_at => nil
        )
      end
      @unpub_count = BlogPost.count "published_at is null"
    end
    
    before :each do
      $cache.flush
      get :index
    end
    
    it "should cache the total number of entries, not the entries on just this page" do
      key =
          "AdminAssistant::Admin::BlogPosts3Controller_count_published_at_is_null_"
      $cache.read(key).should == @unpub_count
      $cache.expires_in(key).should be_close(12.hours, 5.seconds)
    end
  end
  
  describe '#new' do
    before :each do
      @request_time = Time.now.utc
      get :new
    end
    
    it 'should not have a body field' do
      response.should_not have_tag('textarea[name=?]', 'blog_post[body]')
    end
    
    it 'should have a published_at select that starts in the year 2009' do
      name = 'blog_post[published_at(1i)]'
      response.should have_tag('select[name=?]', name) do
        with_tag "option[value='2009']"
        with_tag "option[value='2010']"
        without_tag "option[value='2008']"
      end
    end
    
    it 'should have a published_at select that is set to now' do
      name = 'blog_post[published_at(3i)]'
      response.should have_tag('select[name=?]', name) do
        with_tag "option[value=?][selected=selected]", @request_time.day
      end
    end
    
    it 'should not show a nullify link for published_at' do
      response.body.should_not have_tag(
        'a', :text => "Set \"published at\" to nil"
      )
    end
    
    it "should say 'New post'" do
      response.should have_tag('h2', :text => 'New post')
    end
  end
  
  describe '#show' do
    before :all do
      @blog_post = BlogPost.create! :title => "title", :user => @user
    end
    
    before :each do
      get :show, :id => @blog_post.id
      response.should be_success
    end
    
    it "should say 'Post [ID]'" do
      response.should have_tag('h2', :text => "Post #{@blog_post.id}")
    end
  end
end
