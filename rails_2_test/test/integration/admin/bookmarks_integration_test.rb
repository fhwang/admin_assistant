require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class Admin::BookmarksIntegrationTest < ActionController::IntegrationTest
  def setup
    @user = User.find_or_create_by_username 'soren'
    @blog_post = (BlogPost.find(:first) or
                  BlogPost.create!(:title => random_word, :user => @user))
  end
  
  def setup_15_blog_posts_16_comments_16_products_and_16_users
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

  def test_autocomplete_blog_post_with_one_match  
    get(
      "/admin/bookmarks/autocomplete_blog_post",
      :blog_post_autocomplete_input => @blog_post.title
    )
      
    # should return that match
    assert_select('ul') do
      assert_select(
        "li[id=blog_post#{@blog_post.id}]", :text => @blog_post.title
      )
    end
  end
  
  def test_index_while_not_searching
    setup_15_blog_posts_16_comments_16_products_and_16_users
    get "/admin/bookmarks"
  
    # should be successful
    assert_response :success
  
    # should have base hidden values for the polymorphic fields in the search form
    assert_select('form#search_form') do
      assert_select(
        'input:not([value])[type=hidden][name=?][id=?]',
        'search[bookmarkable_id]', 'search_bookmarkable_id'
      )
      assert_select(
        'input:not([value])[type=hidden][name=?][id=?]',
        'search[bookmarkable_type]', 'search_bookmarkable_type'
      )
    end
  
    # should show autocompleters for products and users in its search form
    assert_select('form#search_form') do
      [Product, User].each do |model_class|
        name = model_class.name.downcase
        assert_select(
          "input:not([value])[id=bookmarkable_#{name}_autocomplete_input]"
        )
        assert_select "div[id=bookmarkable_#{name}_autocomplete_palette]"
        assert_select "div[id=clear_bookmarkable_#{name}_link]"
      end
    end
  
    # should show drop-downs for blog posts in its search form
    assert_select('form#search_form') do
      assert_select(
        "input[id=bookmarkable_blog_post_autocomplete_input]", false
      )
      assert_select('select[name=?]', 'bookmarkable_blog_post_id') do
        assert_select("option[value='']", :text => '')
        assert_select 'option[value=?]', @blog_post.id
      end
    end
  
    # should show ID entry for comments since it has no default_name_method
    assert_select('form#search_form') do
      assert_select('select[name=?]', 'bookmarkable_comment_id', false)
      assert_select 'input[name=?]', 'bookmarkable_comment_id'
    end
  
    # should show bookmarkable fields, using the target's default name method if it can find one
    assert_select(
      'tr[id=?]', "bookmark_#{@blog_post_bookmark.id}"
    ) do
      assert_select(
        'td', :text => "Blog post '#{@blog_post.title}'"
      )
    end
    assert_select(
      'tr[id=?]', "bookmark_#{@comment_bookmark.id}"
    ) do
      assert_select 'td', :text => "Comment #{@comment.id}"
    end
    assert_select(
      'tr[id=?]', "bookmark_#{@product_bookmark.id}"
    ) do
      assert_select 'td', :text => "Product '#{@product.name}'"
    end
    assert_select(
      'tr[id=?]', "bookmark_#{@user_bookmark.id}"
    ) do
      assert_select 'td', :text => "User '#{@user.username}'"
    end
  end
  
  def test_index_while_searching_by_bookmarked_blog_post
    setup_15_blog_posts_16_comments_16_products_and_16_users
    get(
      "/admin/bookmarks",
      :search => {
        :bookmarkable_type => 'BlogPost', :bookmarkable_id => @blog_post.id
      }
    )
  
    # should be successful
    assert_response :success
  
    # should have base hidden values for the polymorphic fields in the search form
    assert_select('form#search_form') do
      assert_select(
        'input[type=hidden][name=?][id=?][value=?]',
        'search[bookmarkable_id]', 'search_bookmarkable_id', @blog_post.id
      )
      assert_select(
        'input[type=hidden][name=?][id=?][value=?]',
        'search[bookmarkable_type]', 'search_bookmarkable_type', 'BlogPost'
      )
    end
  
    # should show autocompleters for products and users in its search form
    assert_select('form#search_form') do
      [Product, User].each do |model_class|
        name = model_class.name.downcase
        assert_select(
          "input:not([value])[id=bookmarkable_#{name}_autocomplete_input]"
        )
        assert_select "div[id=bookmarkable_#{name}_autocomplete_palette]"
        assert_select "div[id=clear_bookmarkable_#{name}_link]"
      end
    end
  
    # should show drop-downs for blog posts in its search form
    assert_select('form#search_form') do
      assert_select(
        "input[id=bookmarkable_blog_post_autocomplete_input]", false
      )
      assert_select('select[name=?]', 'bookmarkable_blog_post_id') do
        assert_select("option[value='']", :text => '')
        assert_select 'option[value=?][selected=selected]', @blog_post.id
      end
    end
  
    # should show ID entry for comments since it has no default_name_method
    assert_select('form#search_form') do
      assert_select('select[name=?]', 'bookmarkable_comment_id', false)
      assert_select 'input[name=?]', 'bookmarkable_comment_id'
    end
  
    # should only show bookmarks of that blog post
    assert_select(
      'tr[id=?]', "bookmark_#{@blog_post_bookmark.id}"
    )
    excluded_bookmarks = [
      @comment_bookmark, @product_bookmark, @user_bookmark
    ]
    excluded_bookmarks.each do |bookmark|
      assert_select('tr[id=?]', "bookmark_#{bookmark.id}", false)
    end
  end
  
  def test_index_while_searching_by_bookmarked_product
    setup_15_blog_posts_16_comments_16_products_and_16_users
    get(
      "/admin/bookmarks",
      :search => {
        :bookmarkable_type => 'Product',
        :bookmarkable_id => @product_bookmark.bookmarkable_id
      }
    )
  
    # should be successful
    assert_response :success
  
    # should have base hidden values for the polymorphic fields in the search form
    assert_select('form#search_form') do
      assert_select(
        'input[type=hidden][name=?][id=?][value=?]',
        'search[bookmarkable_id]', 'search_bookmarkable_id',
        @product_bookmark.bookmarkable_id
      )
      assert_select(
        'input[type=hidden][name=?][id=?][value=?]',
        'search[bookmarkable_type]', 'search_bookmarkable_type', 'Product'
      )
    end
  
    # should show autocompleters for products and users in its search form
    assert_select('form#search_form') do
      assert_select(
        "input[id=bookmarkable_product_autocomplete_input][value=?]",
        "#{@product_bookmark.bookmarkable.name}"
      )
      assert_select "div[id=bookmarkable_product_autocomplete_palette]"
      assert_select "div[id=clear_bookmarkable_product_link]"
      assert_select(
        "input:not([value])[id=bookmarkable_user_autocomplete_input]"
      )
      assert_select "div[id=bookmarkable_user_autocomplete_palette]"
      assert_select "div[id=clear_bookmarkable_user_link]"
    end
  
    # should show drop-downs for blog posts in its search form
    assert_select('form#search_form') do
      assert_select(
        "input[id=bookmarkable_blog_post_autocomplete_input]", false
      )
      assert_select('select[name=?]', 'bookmarkable_blog_post_id') do
        assert_select("option[value='']", :text => '')
        assert_select 'option[value=?]', @blog_post.id
      end
    end
  
    # should show only bookmarks of that product
    assert_select(
      'tr[id=?]', "bookmark_#{@product_bookmark.id}"
    )
    excluded_bookmarks = [
      @blog_post_bookmark, @comment_bookmark, @user_bookmark
    ]
    excluded_bookmarks.each do |bookmark|
      assert_select('tr[id=?]', "bookmark_#{bookmark.id}", false)
    end
  
    # should show ID entry for comments since it has no default_name_method
    assert_select('form#search_form') do
      assert_select('select[name=?]', 'bookmarkable_comment_id', false)
      assert_select 'input[name=?]', 'bookmarkable_comment_id'
    end
  end
  
  def test_index_while_searching_by_bookmarked_comment
    setup_15_blog_posts_16_comments_16_products_and_16_users
    get(
      "/admin/bookmarks",
      :search => {
        :bookmarkable_type => 'Comment',
        :bookmarkable_id => @comment_bookmark.bookmarkable_id
      }
    )
  
    # should be successful
    assert_response :success
  
    # should have base hidden values for the polymorphic fields in the search form
    assert_select('form#search_form') do
      assert_select(
        'input[type=hidden][name=?][id=?][value=?]',
        'search[bookmarkable_id]', 'search_bookmarkable_id',
        @comment_bookmark.bookmarkable_id
      )
      assert_select(
        'input[type=hidden][name=?][id=?][value=?]',
        'search[bookmarkable_type]', 'search_bookmarkable_type', 'Comment'
      )
    end
  
    # should show autocompleters for products and users in its search form
    assert_select('form#search_form') do
      [Product, User].each do |model_class|
        name = model_class.name.downcase
        assert_select(
          "input:not([value])[id=bookmarkable_#{name}_autocomplete_input]"
        )
        assert_select "div[id=bookmarkable_#{name}_autocomplete_palette]"
        assert_select "div[id=clear_bookmarkable_#{name}_link]"
      end
    end
  
    # should show drop-downs for blog posts in its search form
    assert_select('form#search_form') do
      assert_select("input[id=blog_post_autocomplete_input]", false)
      assert_select('select[name=?]', 'bookmarkable_blog_post_id') do
        assert_select("option[value='']", :text => '')
        assert_select 'option[value=?]', @blog_post.id
      end
    end
  
    # should show only bookmarks of that comment
    assert_select(
      'tr[id=?]', "bookmark_#{@comment_bookmark.id}"
    )
    excluded_bookmarks = [
      @blog_post_bookmark, @product_bookmark, @user_bookmark
    ]
    excluded_bookmarks.each do |bookmark|
      assert_select('tr[id=?]', "bookmark_#{bookmark.id}", false)
    end
  
  # should show ID entry for comments since it has no default_name_method
    assert_select('form#search_form') do
      assert_select('select[name=?]', 'bookmarkable_comment_id', false)
      assert_select(
        'input[name=?][value=?]', 'bookmarkable_comment_id', 
        @comment_bookmark.bookmarkable_id
      )
    end
  end
  
  def test_index_with_bookmarks_of_different_blog_posts_by_different_users
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
    
    get(
      "/admin/bookmarks", 
      :search => {
        '(all_or_any)' => 'any', :bookmarkable_type => 'BlogPost', 
        :bookmarkable_id => @blog_post.id, :user_id => @user.id
      }
    )
  
    # should include bookmarks of the blog post
    assert_select(
      'tr[id=?]', "bookmark_#{@user_blog_post_bookmark.id}"
    )
    assert_select(
      'tr[id=?]', "bookmark_#{@user2_blog_post_bookmark.id}"
    )
  
    # should exclude bookmarks of other blog posts by other users
    assert_select(
      'tr[id=?]', "bookmark_#{@user2_blog_post2_bookmark.id}", false
    )
  
    # should include bookmarks from the user
    assert_select(
      'tr[id=?]', "bookmark_#{@user_blog_post_bookmark.id}"
    )
    assert_select(
      'tr[id=?]', "bookmark_#{@user_blog_post2_bookmark.id}"
    )
  
    # should exclude bookmarks of other bookmarkable types by other users
    assert_select(
      'tr[id=?]', "bookmark_#{@user2_product_bookmark.id}", false
    )
  end
  
  def test_index_with_a_blank_search
    Bookmark.destroy_all
    @blog_post_bookmark = Bookmark.create!(
      :user => @user, :bookmarkable => @blog_post
    )
    
    get(
      "/admin/bookmarks",
      :search => {
        :bookmarkable_type => '', :bookmarkable_id => '', :user_id => '', 
        '(all_or_any)' => 'all'
      }
    )
  
    # should be successful
    assert_response :success
  
    # should include the bookmarks
    assert_select(
      'tr[id=?]', "bookmark_#{@blog_post_bookmark.id}"
    )
  end
  
  def test_edit
    @bookmark = Bookmark.create! :user => @user, :bookmarkable => @blog_post
    
    get "/admin/bookmarks/edit/#{@bookmark.id}"
    
    # should have a 'Bookmarkable' field
    bt_name = 'bookmark[bookmarkable_type]'
    assert_select('select[name=?]', bt_name) do
      assert_select 'option[value=BlogPost][selected=selected]',
               :text => 'BlogPost'
      assert_select 'option[value=Comment]', :text => 'Comment'
      assert_select 'option[value=Product]', :text => 'Product'
      assert_select 'option[value=User]', :text => 'User'
    end
    assert_select(
      'input[name=?][value=?]', 'bookmark[bookmarkable_id]', @blog_post.id
    )
  end
  
  def test_new
    get "/admin/bookmarks/new"
    
    # should be successful
    assert_response :success
    
    # should not have a 'Bookmarkable type' field label
    assert_no_match(%r|<label[^>]*>Bookmarkable type</label>|, response.body)
    
    # should have a 'Bookmarkable' field
    assert_select('label', :text => 'Bookmarkable')
    bt_name = 'bookmark[bookmarkable_type]'
    assert_select('select[name=?]', bt_name) do
      assert_select 'option[value=BlogPost]', :text => 'BlogPost'
      assert_select 'option[value=Comment]', :text => 'Comment'
      assert_select 'option[value=Product]', :text => 'Product'
      assert_select 'option[value=User]', :text => 'User'
    end
    assert_select('input[name=?]', 'bookmark[bookmarkable_id]')
  end
end
