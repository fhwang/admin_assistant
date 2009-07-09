require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::BookmarksController do
  integrate_views
  
  before :all do
    @user = User.find_or_create_by_username 'soren'
    @blog_post = (BlogPost.find(:first) or
                  BlogPost.create!(:title => random_word, :user => @user))
  end
  
  describe '#autocomplete_blog_post' do
    describe 'with one match' do
      before :each do
        get(
          :autocomplete_blog_post,
          :blog_post_autocomplete_input => @blog_post.title
        )
      end
      
      it 'should return that match' do
        response.should have_tag('ul') do
          with_tag(
            "li[id=blog_post#{@blog_post.id}]", :text => @blog_post.title
          )
        end
      end
    end
  end
  
  describe '#index with less than 15 blog posts, 16 comments, 16 products, and 16 users' do
    before :all do
      Bookmark.destroy_all
      @blog_post_bookmark = Bookmark.create!(
        :user => @user, :bookmarkable => @blog_post
      )
      BlogPost.count.downto(14) do
        bp = BlogPost.find :first, :conditions => ['id != ?', @blog_post.id]
        bp.destroy
      end
      Comment.count.upto(16) do
        Comment.create!(
          :user => @user, :blog_post => @blog_post, :comment => random_word
        )
      end
      @comment = Comment.first
      @comment_bookmark = Bookmark.create!(
        :user => @user, :bookmarkable => @comment
      )
      Product.count.upto(16) do
        Product.create! :name => random_word
      end
      @product = Product.first
      @product_bookmark = Bookmark.create!(
        :user => @user, :bookmarkable => @product
      )
      User.count.upto(16) do
        User.create! :username => random_word
      end
      @user_bookmark = Bookmark.create! :user => @user, :bookmarkable => @user
    end
    
    describe 'while not searching' do
      before :each do
        get :index
      end
      
      it 'should be successful' do
        response.should be_success
      end
      
      it 'should have base hidden values for the polymorphic fields in the search form' do
        response.should have_tag('form#search_form') do
          with_tag(
            'input:not([value])[type=hidden][name=?][id=?]',
            'search[bookmarkable_id]', 'search_bookmarkable_id'
          )
          with_tag(
            'input:not([value])[type=hidden][name=?][id=?]',
            'search[bookmarkable_type]', 'search_bookmarkable_type'
          )
        end
      end
      
      it 'should show autocompleters for products and users in its search form' do
        response.should have_tag('form#search_form') do
          [Product, User].each do |model_class|
            name = model_class.name.downcase
            with_tag(
              "input:not([value])[id=bookmarkable_#{name}_autocomplete_input]"
            )
            with_tag "div[id=bookmarkable_#{name}_autocomplete_palette]"
            with_tag "div[id=clear_bookmarkable_#{name}_link]"
          end
        end
      end
      
      it 'should show drop-downs for blog posts in its search form' do
        response.should have_tag('form#search_form') do
          without_tag "input[id=bookmarkable_blog_post_autocomplete_input]"
          with_tag('select[name=?]', 'bookmarkable_blog_post_id') do
            with_tag("option[value='']", :text => '')
            with_tag 'option[value=?]', @blog_post.id
          end
        end
      end
      
      it 'should show ID entry for comments since it has no default_name_method' do
        response.should have_tag('form#search_form') do
          without_tag 'select[name=?]', 'bookmarkable_comment_id'
          with_tag 'input[name=?]', 'bookmarkable_comment_id'
        end
      end
      
      it "should show bookmarkable fields, using the target's default name method if it can find one" do
        response.should have_tag(
          'tr[id=?]', "bookmark_#{@blog_post_bookmark.id}"
        ) do
          with_tag(
            'td', :text => "Blog post '#{@blog_post.title}'"
          )
        end
        response.should have_tag(
          'tr[id=?]', "bookmark_#{@comment_bookmark.id}"
        ) do
          with_tag 'td', :text => "Comment #{@comment.id}"
        end
        response.should have_tag(
          'tr[id=?]', "bookmark_#{@product_bookmark.id}"
        ) do
          with_tag 'td', :text => "Product '#{@product.name}'"
        end
        response.should have_tag(
          'tr[id=?]', "bookmark_#{@user_bookmark.id}"
        ) do
          with_tag 'td', :text => "User '#{@user.username}'"
        end
      end
    end
    
    describe 'while searching by bookmarked blog post' do
      before :each do
        get(
          :index,
          :search => {
            :bookmarkable_type => 'BlogPost', :bookmarkable_id => @blog_post.id
          }
        )
      end
      
      it 'should be successful' do
        response.should be_success
      end
      
      it 'should have base hidden values for the polymorphic fields in the search form' do
        response.should have_tag('form#search_form') do
          with_tag(
            'input[type=hidden][name=?][id=?][value=?]',
            'search[bookmarkable_id]', 'search_bookmarkable_id', @blog_post.id
          )
          with_tag(
            'input[type=hidden][name=?][id=?][value=?]',
            'search[bookmarkable_type]', 'search_bookmarkable_type', 'BlogPost'
          )
        end
      end
      
      it 'should show autocompleters for products and users in its search form' do
        response.should have_tag('form#search_form') do
          [Product, User].each do |model_class|
            name = model_class.name.downcase
            with_tag(
              "input:not([value])[id=bookmarkable_#{name}_autocomplete_input]"
            )
            with_tag "div[id=bookmarkable_#{name}_autocomplete_palette]"
            with_tag "div[id=clear_bookmarkable_#{name}_link]"
          end
        end
      end
      
      it 'should show drop-downs for blog posts in its search form' do
        response.should have_tag('form#search_form') do
          without_tag "input[id=bookmarkable_blog_post_autocomplete_input]"
          with_tag('select[name=?]', 'bookmarkable_blog_post_id') do
            with_tag("option[value='']", :text => '')
            with_tag 'option[value=?][selected=selected]', @blog_post.id
          end
        end
      end
      
      it 'should show ID entry for comments since it has no default_name_method' do
        response.should have_tag('form#search_form') do
          without_tag 'select[name=?]', 'bookmarkable_comment_id'
          with_tag 'input[name=?]', 'bookmarkable_comment_id'
        end
      end
      
      it 'should only show bookmarks of that blog post' do
        response.should have_tag(
          'tr[id=?]', "bookmark_#{@blog_post_bookmark.id}"
        )
        excluded_bookmarks = [
          @comment_bookmark, @product_bookmark, @user_bookmark
        ]
        excluded_bookmarks.each do |bookmark|
          response.should_not have_tag('tr[id=?]', "bookmark_#{bookmark.id}")
        end
      end
    end
    
    describe 'while searching by bookmarked product' do
      before :each do
        get(
          :index,
          :search => {
            :bookmarkable_type => 'Product',
            :bookmarkable_id => @product_bookmark.bookmarkable_id
          }
        )
      end
      
      it 'should be successful' do
        response.should be_success
      end
      
      it 'should have base hidden values for the polymorphic fields in the search form' do
        response.should have_tag('form#search_form') do
          with_tag(
            'input[type=hidden][name=?][id=?][value=?]',
            'search[bookmarkable_id]', 'search_bookmarkable_id',
            @product_bookmark.bookmarkable_id
          )
          with_tag(
            'input[type=hidden][name=?][id=?][value=?]',
            'search[bookmarkable_type]', 'search_bookmarkable_type', 'Product'
          )
        end
      end
      
      it 'should show autocompleters for products and users in its search form' do
        response.should have_tag('form#search_form') do
          with_tag(
            "input[id=bookmarkable_product_autocomplete_input][value=?]",
            "#{@product_bookmark.bookmarkable.name}"
          )
          with_tag "div[id=bookmarkable_product_autocomplete_palette]"
          with_tag "div[id=clear_bookmarkable_product_link]"
          with_tag(
            "input:not([value])[id=bookmarkable_user_autocomplete_input]"
          )
          with_tag "div[id=bookmarkable_user_autocomplete_palette]"
          with_tag "div[id=clear_bookmarkable_user_link]"
        end
      end
      
      it 'should show drop-downs for blog posts in its search form' do
        response.should have_tag('form#search_form') do
          without_tag "input[id=bookmarkable_blog_post_autocomplete_input]"
          with_tag('select[name=?]', 'bookmarkable_blog_post_id') do
            with_tag("option[value='']", :text => '')
            with_tag 'option[value=?]', @blog_post.id
          end
        end
      end
      
      it 'should show only bookmarks of that product' do
        response.should have_tag(
          'tr[id=?]', "bookmark_#{@product_bookmark.id}"
        )
        excluded_bookmarks = [
          @blog_post_bookmark, @comment_bookmark, @user_bookmark
        ]
        excluded_bookmarks.each do |bookmark|
          response.should_not have_tag('tr[id=?]', "bookmark_#{bookmark.id}")
        end
      end
      
      it 'should show ID entry for comments since it has no default_name_method' do
        response.should have_tag('form#search_form') do
          without_tag 'select[name=?]', 'bookmarkable_comment_id'
          with_tag 'input[name=?]', 'bookmarkable_comment_id'
        end
      end
    end
    
    describe 'while searching by bookmarked comment' do
      before :each do
        get(
          :index,
          :search => {
            :bookmarkable_type => 'Comment',
            :bookmarkable_id => @comment_bookmark.bookmarkable_id
          }
        )
      end
      
      it 'should be successful' do
        response.should be_success
      end
      
      it 'should have base hidden values for the polymorphic fields in the search form' do
        response.should have_tag('form#search_form') do
          with_tag(
            'input[type=hidden][name=?][id=?][value=?]',
            'search[bookmarkable_id]', 'search_bookmarkable_id',
            @comment_bookmark.bookmarkable_id
          )
          with_tag(
            'input[type=hidden][name=?][id=?][value=?]',
            'search[bookmarkable_type]', 'search_bookmarkable_type', 'Comment'
          )
        end
      end
      
      it 'should show autocompleters for products and users in its search form' do
        response.should have_tag('form#search_form') do
          [Product, User].each do |model_class|
            name = model_class.name.downcase
            with_tag(
              "input:not([value])[id=bookmarkable_#{name}_autocomplete_input]"
            )
            with_tag "div[id=bookmarkable_#{name}_autocomplete_palette]"
            with_tag "div[id=clear_bookmarkable_#{name}_link]"
          end
        end
      end
      
      it 'should show drop-downs for blog posts in its search form' do
        response.should have_tag('form#search_form') do
          without_tag "input[id=blog_post_autocomplete_input]"
          with_tag('select[name=?]', 'bookmarkable_blog_post_id') do
            with_tag("option[value='']", :text => '')
            with_tag 'option[value=?]', @blog_post.id
          end
        end
      end
      
      it 'should show only bookmarks of that comment' do
        response.should have_tag(
          'tr[id=?]', "bookmark_#{@comment_bookmark.id}"
        )
        excluded_bookmarks = [
          @blog_post_bookmark, @product_bookmark, @user_bookmark
        ]
        excluded_bookmarks.each do |bookmark|
          response.should_not have_tag('tr[id=?]', "bookmark_#{bookmark.id}")
        end
      end
      
      it 'should show ID entry for comments since it has no default_name_method' do
        response.should have_tag('form#search_form') do
          without_tag 'select[name=?]', 'bookmarkable_comment_id'
          with_tag(
            'input[name=?][value=?]', 'bookmarkable_comment_id', 
            @comment_bookmark.bookmarkable_id
          )
        end
      end
    end
  end
  
  describe '#index with bookmarks of different blog posts by different users' do
    before :all do
      @user_blog_post_bookmark = Bookmark.create!(
        :user => @user, :bookmarkable => @blog_post
      )
      user2 = User.find_or_create_by_username 'Jean-Paul'
      blog_post2 = BlogPost.create!(:title => random_word, :user => user2)
      @user_blog_post2_bookmark = Bookmark.create!(
        :user => @user, :bookmarkable => blog_post2
      )
      @user2_blog_post_bookmark = Bookmark.create!(
        :user => user2, :bookmarkable => @blog_post
      )
      @user2_blog_post2_bookmark = Bookmark.create!(
        :user => user2, :bookmarkable => blog_post2
      )
      product = Product.find_or_create_by_name 'Chocolate bar'
      @user2_product_bookmark = Bookmark.create!(
        :user => user2, :bookmarkable => product
      )
    end
    
    describe 'while searching by bookmark owner or bookmarked blog post' do
      before :each do
        get(
          :index, 
          :search => {
            '(all_or_any)' => 'any', :bookmarkable_type => 'BlogPost', 
            :bookmarkable_id => @blog_post.id, :user_id => @user.id
          }
        )
      end
      
      it 'should include bookmarks of the blog post' do
        response.should have_tag(
          'tr[id=?]', "bookmark_#{@user_blog_post_bookmark.id}"
        )
        response.should have_tag(
          'tr[id=?]', "bookmark_#{@user2_blog_post_bookmark.id}"
        )
      end
      
      it 'should exclude bookmarks of other blog posts by other users' do
        response.should_not have_tag(
          'tr[id=?]', "bookmark_#{@user2_blog_post2_bookmark.id}"
        )
      end
      
      it 'should include bookmarks from the user' do
        response.should have_tag(
          'tr[id=?]', "bookmark_#{@user_blog_post_bookmark.id}"
        )
        response.should have_tag(
          'tr[id=?]', "bookmark_#{@user_blog_post2_bookmark.id}"
        )
      end
      
      it 'should exclude bookmarks of other bookmarkable types by other users' do
        response.should_not have_tag(
          'tr[id=?]', "bookmark_#{@user2_product_bookmark.id}"
        )
      end
    end
  end
  
  describe '#index with a blank search' do
    before :all do
      Bookmark.destroy_all
      @blog_post_bookmark = Bookmark.create!(
        :user => @user, :bookmarkable => @blog_post
      )
    end
    
    before :each do
      get(
        :index,
        :search => {
          :bookmarkable_type => '', :bookmarkable_id => '', :user_id => '', 
          '(all_or_any)' => 'all'
        }
      )
    end
    
    it 'should be successful' do
      response.should be_success
    end
    
    it 'should include the bookmarks' do
      response.should have_tag(
        'tr[id=?]', "bookmark_#{@blog_post_bookmark.id}"
      )
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
