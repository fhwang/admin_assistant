require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::BookmarksController do
  integrate_views
  
  before :all do
    @user = User.find_or_create_by_username 'soren'
    @blog_post = BlogPost.find(:first) or
                BlogPost.create!(:title => random_word, :user => @user)
  end
  
  describe '#index with one bookmark' do
    before :all do
      Bookmark.create! :user => @user, :bookmarkable => @blog_post
    end
    
    before :each do
      get :index
    end
    
    it 'should be successful' do
      response.should be_success
    end
  end
  
  describe '#edit' do
    before :all do
      @bookmark = Bookmark.create! :user => @user, :bookmarkable => @blog_post
    end
    
    before :each do
      get :edit, :id => @bookmark.id
    end
    
    it "should have a 'Bookmarkable' field" do
      bt_name = 'bookmark[bookmarkable_type]'
      response.should have_tag('select[name=?]', bt_name) do
        with_tag 'option[value=BlogPost][selected=selected]',
                 :text => 'BlogPost'
        with_tag 'option[value=Comment]', :text => 'Comment'
        with_tag 'option[value=Product]', :text => 'Product'
        with_tag 'option[value=User]', :text => 'User'
      end
      response.should have_tag(
        'input[name=?][value=?]', 'bookmark[bookmarkable_id]', @blog_post.id
      )
    end
  end
  
  describe '#new' do
    before :each do
      get :new
    end
    
    it 'should be successful' do
      response.should be_success
    end
    
    it "should not have a 'Bookmarkable type' field label" do
      response.should_not have_tag('label', :text => 'Bookmarkable type')
    end
    
    it "should have a 'Bookmarkable' field" do
      response.should have_tag('label', :text => 'Bookmarkable')
      bt_name = 'bookmark[bookmarkable_type]'
      response.should have_tag('select[name=?]', bt_name) do
        with_tag 'option[value=BlogPost]', :text => 'BlogPost'
        with_tag 'option[value=Comment]', :text => 'Comment'
        with_tag 'option[value=Product]', :text => 'Product'
        with_tag 'option[value=User]', :text => 'User'
      end
      response.should have_tag('input[name=?]', 'bookmark[bookmarkable_id]')
    end
  end
end
