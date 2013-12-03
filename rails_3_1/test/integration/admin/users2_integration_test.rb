require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class Admin::Users2IntegrationTest < ActionController::IntegrationTest
  def test_index
    User.create!(:username => random_word) if User.count == 0
    get "/admin/users2"
  
    # should show the empty search form
    assert_select('form#search_form') do
      assert_select('input[name=?]', 'search[blog_posts]')
    end
  end

  def test_index_when_searching_by_blog_post
    User.destroy_all
    @soren = User.create! :username => 'soren'
    @jean_paul = User.create! :username => 'jean_paul'
    BlogPost.create!(
      :user => @jean_paul, :title => 'No Foobar',
      :body => 'Hell is other foobars'
    )
    @friedrich = User.create! :username => 'friedrich'
    BlogPost.create!(
      :user => @friedrich, :title => 'Thus Spake Zarafoobar',
      :body => 'Man is something that shall be overfoobared.'
    )
    BlogPost.create!(
      :user => @friedrich, :title => 'Beyond Good and Foobar',
      :body =>
        'And when you gaze long into a foobar the foobar also gazes into you.'
    )
    get "/admin/users2", :search => {:blog_posts => 'foobar'}
  
    # should prefill the search form fields
    assert_select('form#search_form') do
      assert_select('input[name=?][value=?]', 'search[blog_posts]', 'foobar')
    end
    
    # should not match a user without any matching blog posts
    assert_no_match(%r|<td[^>]*>#{@soren.username}</td>|, response.body)
    
    # should match a user with one matching blog post
    assert_select('td', :text => @jean_paul.username)
    
    # should match a user with two matching blog posts, only presenting that user once
    assert_select('td', :text => @friedrich.username, :count => 1)
  end

  def test_index_when_searching_by_street
    User.destroy_all
    @soren = User.create! :username => 'soren'
    @soren.create_address! :street => '123 Main Street'
    @jean_paul = User.create! :username => 'jean_paul'
    @jean_paul.create_address! :street => '456 Sunny Lane'
    get "/admin/users2", :search => {:street => '123'}
    assert_select('td', :text => @soren.username)
    assert_no_match(%r|<td[^>]*>#{@jean_paul.username}</td>|, response.body)
  end
end
