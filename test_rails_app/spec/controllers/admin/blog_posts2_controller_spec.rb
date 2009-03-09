require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::BlogPosts2Controller do
  integrate_views
  
  before :all do
    User.destroy_all
    @user = User.create! :username => 'soren'
  end
  
  describe '#create' do
    describe 'when there are no validation errors' do
      before :each do
        title = random_word
        post(
          :create,
          :blog_post => {
            :title => title, :tags => 'tag1 tag2', :publish => '1',
            :user_id => @user.id
          }
        )
        @blog_post = BlogPost.find_by_title title
      end
      
      it 'should create a new BlogPost' do
        @blog_post.should_not be_nil
      end
      
      it 'should create tags' do
        @blog_post.should have(2).tags
        %w(tag1 tag2).each do |tag_str|
          assert(@blog_post.tags.any? { |tag| tag.tag == tag_str })
        end
      end
      
      it 'should set published_at because of the publish flag' do
        @blog_post.published_at.should_not be_nil
      end
    end
    
    describe "when the user has clicked 'Preview'" do
      before :each do
        title = random_word
        post(
          :create,
          :blog_post => {
            :title => title, :tags => 'tag1 tag2', :publish => '1',
            :user_id => @user.id
          },
          :commit => 'Preview'
        )
        @blog_post = BlogPost.find_by_title title
      end

      it 'should redirect to the edit page with the preview flag' do
        response.should redirect_to(
          :action => 'edit', :id => @blog_post.id, :preview => '1'
        )
      end
    end
  end
  
  describe '#edit' do
    before :all do
      BlogPost.destroy_all
      @blog_post = BlogPost.create!(
        :title => "blog post title", :body => 'blog post body', :user => @user
      )
      tag1 = Tag.create! :tag => 'tag1'
      BlogPostTag.create! :blog_post => @blog_post, :tag => tag1
      tag2 = Tag.create! :tag => 'tag2'
      BlogPostTag.create! :blog_post => @blog_post, :tag => tag2
    end
      
    before :each do
      get :edit, :id => @blog_post.id
      response.should be_success
    end
    
    it 'should show the tags' do
      response.body.should match(%r|<input.*name="blog_post\[tags\]"|m)
      response.body.should match(/(tag2 tag1|tag1 tag2)/)
    end
    
    it 'should show a preview button' do
      response.should have_tag('input[type=submit][value=Preview]')
    end
  end
  
  describe '#edit in preview mode' do
    before :all do
      @blog_post = BlogPost.create!(
        :title => "blog post title", :body => 'blog post body', :user => @user
      )
    end
    
    before :each do
      get :edit, :id => @blog_post.id, :preview => '1'
      response.should be_success
    end

    it 'should render the preview HTML' do
      response.should have_tag('h4', 'Preview')
    end
  end

  describe '#index' do
    describe 'when there is one record' do
      before :all do
        BlogPost.destroy_all
        @blog_post = BlogPost.create!(
          :title => "blog post title", :body => 'blog post body',
          :user => @user
        )
        tag1 = Tag.create! :tag => 'tag1'
        BlogPostTag.create! :blog_post => @blog_post, :tag => tag1
        tag2 = Tag.create! :tag => 'tag2'
        BlogPostTag.create! :blog_post => @blog_post, :tag => tag2
      end
      
      before :each do
        get :index
        response.should be_success
      end
    
      it 'should show the tags' do
        response.body.should match(/(tag2 tag1|tag1 tag2)/)
      end
    
      it 'should show the title' do
        response.body.should match(/blog post title/)
      end
      
      it 'should not show the body' do
        response.body.should_not match(/blog post body/)
      end
      
      it 'should show a link to the all index page' do
        response.body.should match(%r|<a.*href="/admin/blog_posts2\?all=1"|)
      end
      
      it 'should not show a sort link for tags' do
        response.should_not have_tag("a", :text => 'Tags')
      end
      
      it 'should show a sort link for users' do
        assert_a_tag_with_get_args(
          'Author', '/admin/blog_posts2',
          {:sort => 'user', :sort_order => 'asc'}, response.body
        )
      end
      
      it "should say username because that's one of our default name fields" do
        response.should have_tag('td', :text => 'soren')
      end
      
      it "should say 'Yes' or 'No' for the textile field" do
        response.body.should match(/No/)
      end
    end
    
    describe 'when there is one published post and one unpublished post' do
      before :all do
        BlogPost.create! :title => "--unpublished--", :user => @user
        BlogPost.create!(
          :title => "--published--", :published_at => Time.now.utc,
          :user => @user
        )
      end
      
      before :each do
        get :index
        response.should be_success
      end
      
      it 'should show the unpublished post' do
        response.body.should match(/--unpublished--/)
      end
      
      it 'should not show the published post' do
        response.body.should_not match(/--published--/)
      end
    end
  end
  
  describe '#index?all=1' do
    before :all do
      BlogPost.create!(
        :title => "--published--", :published_at => Time.now.utc,
        :user => @user
      )
    end
      
    before :each do
      get :index, :all => '1'
      response.should be_success
    end

    it 'should show published posts' do
      response.body.should match(/--published--/)
    end
  end
  
  describe '#index?all=1 with two published posts' do
    before :all do
      BlogPost.create!(
        :title => 'published later', :published_at => Time.utc(2009, 2, 1),
        :user => @user
      )
      BlogPost.create!(
        :title => 'published earlier', :published_at => Time.utc(2009, 1, 1),
        :user => @user
      )
    end
    
    before :each do
      get :index, :all => '1'
    end
    
    it 'should order by published_at desc' do
      response.body.should match(/published later.*published earlier/m)
    end
  end
  
  describe '#new' do
    before :all do
      Tag.create! :tag => 'tag_from_yesterday'
    end
    
    before :each do
      get :new
    end
    
    it 'should show a field for tags' do
      response.body.should match(%r|<input.*name="blog_post\[tags\]"|m)
    end
    
    it 'should show current tags' do
      response.body.should match(/tag_from_yesterday/)
    end
    
    it "should show a checkbox for the 'publish' virtual field" do
      response.body.should match(
        %r!
          <input[^>]*
          (name="blog_post\[publish\][^>]*type="checkbox"[^>]value="1"|
           type="checkbox"[^>]*name="blog_post\[publish\][^>]value="1")
        !x
      )
      # needs hidden field, like form.check_box
      response.body.should match(
        %r!
          <input[^>]*
          (name="blog_post\[publish\][^>]*type="hidden"[^>]value="0"|
          type="hidden"[^>]*name="blog_post\[publish\][^>]value="0")
        !x
      )
    end
    
    it 'should show a preview button' do
      response.should have_tag('input[type=submit][value=Preview]')
    end
    
    it 'should use a textarea for the body field' do
      response.body.should match(
        %r|<textarea.*name="blog_post\[body\]".*>.*</textarea>|
      )
    end
    
    it "should use a checkbox for the boolean field 'textile'" do
      response.body.should match(
        %r!
          <input[^>]*
          (name="blog_post\[textile\][^>]*type="checkbox"|
           type="checkbox"[^>]*name="blog_post\[textile\])
        !x
      )
    end
    
    it "should say 'Author' instead of 'User'" do
      response.body.should match(/Author/)
    end
  end
  
  describe '#update' do
    before :all do
      @blog_post = BlogPost.create! :title => random_word, :user => @user
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
end
