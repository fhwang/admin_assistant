require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::BlogPostsCustomNewAndEditController do
  integrate_views
  
  before :all do
    User.destroy_all
    @user = User.create! :username => 'soren'
  end
  
  describe '#index with one blog post' do
    before :all do
      BlogPost.destroy_all
      @blog_post = BlogPost.create!(
        :title => "hi there", :user => @user, :textile => false
      )
    end
      
    before :each do
      get :index
      response.should be_success
    end
    
    it 'should have a new link' do
      response.should have_tag(
        "a[href=/admin/blog_posts_custom_new_and_edit/new]", 'New blog post'
      )
    end
      
    it 'should have an edit link' do
      response.should have_tag('td.actions') do
        with_tag(
          "a[href=/admin/blog_posts_custom_new_and_edit/edit/#{@blog_post.id}]",
          'Edit'
        )
      end
    end

    it 'should have a destroy link' do
      response.should have_tag('td.actions') do
        with_tag(
          "a[href=#]",
          'Delete'
        )
      end
    end

    it 'should have a show link' do
      response.should have_tag('td.actions') do
        with_tag(
          "a[href=/admin/blog_posts_custom_new_and_edit/show/#{@blog_post.id}]",
          'Show'
        )
      end
    end
  end
  
  describe "#index with helper methods suppressing links" do
    before :all do
      BlogPost.destroy_all
      @blog_post = BlogPost.create!(
        :title => "hi there", :user => @user, :textile => false
      )
    end
      
    before :each do
      get :index, :flag_to_trigger_helper_methods => '1'
      response.should be_success
    end
    
    it 'should not have a new link' do
      response.should_not have_tag(
        "a[href=/admin/blog_posts_custom_new_and_edit/new]", 'New blog post'
      )
    end
      
    it 'should not have an edit link' do
      response.should_not have_tag(
        "td.actions a[href=/admin/blog_posts_custom_new_and_edit/edit/#{@blog_post.id}]",
        'Edit'
      )
    end
    
    it 'should not have a destroy link' do
      response.should_not have_tag("td.actions a[href=#]", 'Delete')
    end

    it 'should not have a show link' do
      response.should_not have_tag("td.actions a[href=/admin/blog_posts_custom_new_and_edit/show/#{@blog_post.id}]", 'Show')
    end
    
    it 'should not have a search link' do
      response.should_not have_tag(
        "a", 'Search'
      )
    end
    
  end
end
