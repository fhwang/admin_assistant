require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::BlogPosts2Controller do
  integrate_views
  
  describe '#edit' do
    before :all do
      BlogPost.destroy_all
      @blog_post = BlogPost.create!(
        :title => "blog post title", :body => 'blog post body'
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
  end

  describe '#index' do
    describe 'when there is one record' do
      before :all do
        BlogPost.destroy_all
        @blog_post = BlogPost.create!(
          :title => "blog post title", :body => 'blog post body'
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
    end
  end
  
  describe '#new' do
    before :each do
      get :new
    end
    
    it 'should show a field for tags' do
      response.body.should match(%r|<input.*name="blog_post\[tags\]"|m)
    end
  end
end
