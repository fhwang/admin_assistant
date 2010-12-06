require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::BlogPosts2Controller do
  integrate_views
  
  before :all do
    User.destroy_all
    @user = User.create! :username => 'soren'
  end
  
  describe '#show' do
    before :all do
      @blog_post = BlogPost.create! :title => random_word, :user => @user
    end
    
    before :each do
      get :show, :id => @blog_post.id
      response.should be_success
    end
    
    it 'should show user' do
      response.body.should match(/soren/)
    end
    
    it 'should not show created at' do
      response.body.should_not match(/Created at/)
    end
  end
  
  describe '#update' do
    before :all do
      @blog_post = BlogPost.create! :title => random_word, :user => @user
    end
    
    describe 'when there are no validation errors' do
      before :each do
        post(
          :update,
          :id => @blog_post.id, :blog_post => {:tags => 'tag1 tag2 tag3'}
        )
      end
      
      it 'should set the tags_string' do
        @blog_post.reload.tags_string.should match(/tag1,tag2,tag3/)
      end
    end
    
    describe "when the user has clicked 'Preview'" do
      before :each do
        title2 = random_word
        post(
          :update,
          :id => @blog_post.id, :blog_post => {:title => title2},
          :commit => 'Preview'
        )
      end
      
      it 'should redirect to the edit page with the preview flag' do
        response.should redirect_to(
          :action => 'edit', :id => @blog_post.id, :preview => '1'
        )
      end
    end
  end

  describe '#update with a bad tag' do
    before :all do
      @blog_post = BlogPost.create! :title => random_word, :user => @user
    end
    
    before :each do
      post(
        :update,
        :id => @blog_post.id,
        :blog_post => {:tags => "foo bar! baz"}
      )
    end
    
    it 'should render a useful error' do
      response.should have_tag("div.errorExplanation") do
        with_tag 'li', :text => "Tags contain invalid string 'bar!'"
      end
    end
    
    it 'should highlight the tag string entry' do
      response.should have_tag("div.fieldWithErrors") do
        with_tag "input[name=?][value=?]", "blog_post[tags]", "foo bar! baz"
      end
    end
  end
  
  describe '#update with a bad tag and a missing title' do
    before :all do
      @blog_post = BlogPost.create! :title => random_word, :user => @user
    end
    
    before :each do
      post(
        :update,
        :id => @blog_post.id,
        :blog_post => {:tags => "foo bar! baz", :title => ''}
      )
    end
    
    it 'should render a useful tags error' do
      response.should have_tag("div.errorExplanation") do
        with_tag 'li', :text => "Tags contain invalid string 'bar!'"
      end
    end
    
    it 'should highlight the tag string entry' do
      response.should have_tag("div.fieldWithErrors") do
        with_tag "input[name=?][value=?]", "blog_post[tags]", "foo bar! baz"
      end
    end
    
    it 'should render a useful title error' do
      response.should have_tag("div.errorExplanation") do
        with_tag 'li', :text => "Title can't be blank"
      end
    end
    
    it 'should highlight the title string entry' do
      response.should have_tag("div.fieldWithErrors") do
        with_tag "input[name=?][value=?]", "blog_post[title]", ""
      end
    end
  end
end
