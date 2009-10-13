require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::BlogPosts6Controller do
  integrate_views
  
  before :all do
    User.destroy_all
    @user = User.create! :username => 'soren'
  end
  
  describe '#index' do
    describe 'when there is one record and 15 or less users' do
      before :all do
        BlogPost.destroy_all
        @blog_post = BlogPost.create!(
          :title => "blog post title", :body => 'blog post body',
          :user => @user
        )
        tag1 = Tag.find_or_create_by_tag 'tag1'
        BlogPostTag.create! :blog_post => @blog_post, :tag => tag1
        tag2 = Tag.find_or_create_by_tag 'tag2'
        BlogPostTag.create! :blog_post => @blog_post, :tag => tag2
        User.count.downto(15) do
          user = User.find(:first, :conditions => ['id != ?', @user.id])
          user.destroy
        end
      end
      
      before :each do
        get :index
        response.should be_success
      end
    
      it 'should show a link to /admin/comments/new because extra_right_column_links_for_index is defined in the helper' do
        response.should have_tag('td') do
          with_tag(
            "a[href=?]",
            "/admin/comments/new?comment%5Bblog_post_id%5D=#{@blog_post.id}",
            :text => "New comment"
          )
        end
      end
    end
  end
end
