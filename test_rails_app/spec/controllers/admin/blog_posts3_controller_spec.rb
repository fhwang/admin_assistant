require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::BlogPosts3Controller do
  integrate_views
  
  before :all do
    User.destroy_all
    @user = User.create! :username => 'soren', :password => 'password'
  end
  
  describe '#edit' do
    before :all do
      @blog_post = BlogPost.create! :title => random_word, :user => @user
    end
    
    before :each do
      get :edit, :id => @blog_post.id
    end
    
    it 'should have a body field' do
      response.should have_tag('textarea[name=?]', 'blog_post[body]')
    end
    
    it 'should not include textile' do
      response.body.should_not match(/textile/)
    end
  end
  
  describe '#index' do
    describe 'with no blog posts' do
      before :all do
        BlogPost.destroy_all
      end
      
      before :each do
        get :index
        response.should be_success
      end

      it 'should use the activescaffold-themed CSS' do
        response.should have_tag(
          'link[href^=/stylesheets/admin_assistant_activescaffold.css]'
        )
      end
      
      it "should say 'Posts'" do
        response.should have_tag('h2', :text => 'Posts')
      end
    end
    
    describe 'with one unpublished blog post' do
      before :all do
        BlogPost.destroy_all
        @blog_post = BlogPost.create!(
          :title => "unpublished blog post", :user => @user,
          :published_at => nil
        )
      end
      
      before :each do
        get :index
      end
      
      it 'should show the blog post' do
        response.body.should match(/unpublished blog post/)
      end
      
      it "should show 'No' from having called BlogPost#published?" do
        response.should have_tag("tr[id=blog_post_#{@blog_post.id}]") do
          with_tag "td", :text => 'No'
        end
      end
    
      it 'should not have a comparator for the ID search field' do
        response.should have_tag('form[id=search_form][method=get]') do
          without_tag("select[name=?]", "search[id(comparator)]")
        end
      end
    end
    
    describe 'with 26 unpublished blog posts' do
      before :all do
        BlogPost.destroy_all
        1.upto(26) do |i|
          BlogPost.create!(
            :title => "--post #{i}--", :user => @user, :published_at => nil
          )
        end
      end
      
      before :each do
        get :index
      end
      
      it 'should not show link to page 2' do
        response.should_not have_tag("a[href=/admin/blog_posts3?page=2]")
      end
      
      it 'should only say 25 blog posts found' do
        response.body.should match(/25 posts found/)
      end
      
      it 'should show a search form with specific fields' do
        response.should have_tag(
          'form[id=search_form][method=get]', :text => /Title/
        ) do
          with_tag('input[name=?]', 'search[title]')
          with_tag('input[name=?]', 'search[body]')
          with_tag('select[name=?]', 'search[textile]') do
            with_tag("option[value='']", :text => '')
            with_tag("option[value='true']", :text => 'true')
            with_tag("option[value='false']", :text => 'false')
          end
          with_tag('label', :text => 'User')
          with_tag('input[name=?]', 'search[user]')
        end
      end
    end
    
    describe 'with a published blog post' do
      before :all do
        BlogPost.destroy_all
        BlogPost.create!(
          :title => "published blog post", :user => @user,
          :published_at => Time.now.utc
        )
      end
      
      before :each do
        get :index
      end
      
      it 'should not show the blog post' do
        response.body.should_not match(/published blog post/)
        response.body.should match(/No posts found/)
      end
    end
    
    describe 'when searching by user' do
      before :all do
        User.destroy_all
        tiffany = User.create!(:username => 'tiffany')
        BlogPost.create! :title => "By Tiffany", :user => tiffany
        BlogPost.create!(
          :title => "Already published", :user => tiffany,
          :published_at => Time.now
        )
        bill = User.create! :username => 'bill', :password => 'parsimony'
        BlogPost.create! :title => "By Bill", :user => bill
        brooklyn_steve = User.create!(
          :username => 'brooklyn_steve', :state => 'NY'
        )
        BlogPost.create! :title => "By Brooklyn Steve", :user => brooklyn_steve
        sadie = User.create!(
          :username => 'Sadie', :password => 'sadie', :state => 'KY'
        )
        BlogPost.create! :title => "By Sadie", :user => sadie
      end
      
      before :each do
        get :index, :search => {
          :body => "", :textile => "", :id => "", :user => 'ny'
        }
        response.should be_success
      end
      
      it 'should match the string to the username' do
        response.body.should match(/By Tiffany/)
      end
      
      it 'should match the string to the password' do
        response.body.should match(/By Bill/)
      end
      
      it 'should match the string to the state' do
        response.body.should match(/By Brooklyn Steve/)
      end
      
      it "should skip blog posts that don't match anything on the user" do
        response.body.should_not match(/By Sadie/)
      end
      
      it 'should skip blog posts that have already been published' do
        response.body.should_not match(/Already published/)
      end
    end
    
    describe 'with blog posts from two different users' do
      before :all do
        aardvark_man = User.create!(:username => 'aardvark_man')
        BlogPost.create! :title => 'AARDVARKS!!!!!1', :user => aardvark_man
        ziggurat = User.create!(:username => 'zigguratz')
        BlogPost.create! :title => "Wanna go climbing?", :user => ziggurat
      end
      
      before :each do
        get :index
        response.should be_success
      end
      
      it 'should sort by username' do
        response.body.should match(%r|AARDVARKS!!!!!1.*Wanna go climbing|m)
      end
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
