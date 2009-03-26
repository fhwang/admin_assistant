require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::BlogPosts3Controller do
  integrate_views
  
  before :all do
    BlogPost.destroy_all
    User.destroy_all
    @user = User.create! :username => 'soren'
  end
  
  describe '#index' do
    before :all do
      1.upto(26) do |i|
        BlogPost.create! :title => "--post #{i}--", :user => @user
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
end
