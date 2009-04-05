require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::BlogPosts3Controller do
  integrate_views
  
  before :all do
    User.destroy_all
    @user = User.create! :username => 'soren'
  end
  
  describe '#index' do
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
        response.body.should match(/25 blog posts found/)
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
        response.body.should match(/No blog posts found/)
      end
    end
  end
end
