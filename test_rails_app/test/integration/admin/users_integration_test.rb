require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class Admin::UsersIntegrationTest < ActionController::IntegrationTest
  def setup
    @user = User.find_or_create_by_username 'betty'
    @user.update_attribute :password, 'crocker'
  end
  
  def test_create
    post(
      "/admin/users/create", :user => { :username => 'bill', :password => '' }
    )
    
    # should assign a new random password
    user = User.find_by_username 'bill'
    assert_not_nil(user)
    assert_not_equal(user.password, '')
  end
  
  def test_create_with_the_same_username
    @user_count = User.count
    post(
      "/admin/users/create", :user => {:username => 'betty', :password => ''}
    )
    
    # should not save a new user
    assert_equal(User.count, @user_count)
    
    # should not call after_save
    assert_response :success
  end
  
  def test_destroy
    post "/admin/users/destroy/#{@user.id}"
    
    # should destroy the user
    assert_nil(User.find_by_id(@user.id))
  end
  
  def test_edit
    @user.update_attributes(
      :has_avatar => true, :avatar_version => 9,
      :force_blog_posts_to_textile => true
    )
    get "/admin/users/edit/#{@user.id}"
    
    # should show the default text input for password
    assert_match(%r|<input[^>]*name="user\[password\]"|, response.body)
    
    # should show a reset password checkbox
    assert_select("input[type=checkbox][name=reset_password]")
    
    # should have a multipart form
    assert_select('form[enctype=multipart/form-data]')
    
    # should have a file input for tmp_avatar
    assert_select('input[name=?][type=file]', 'user[tmp_avatar]')
    
    # should show the current tmp_avatar with a custom src
    assert_select(
      "img[src^=?]", "http://my-image-server.com/users/#{@user.id}.jpg?v=9"
    )
    
    # should have a remove-image option
    assert_select("input[type=checkbox][name=?]", 'user[tmp_avatar(destroy)]')
    
    # should show a drop-down for force_blog_posts_to_textile
    assert_select('select[name=?]', 'user[force_blog_posts_to_textile]') do
      assert_select "option:not([selected])[value='']"
      assert_select "option:not([selected])[value=0]", :text => 'false'
      assert_select "option[selected=selected][value=1]", :text => 'true'
    end
  end
  
  def test_index
    get "/admin/users"
    
    # should show a Delete link and a link to the profile page
    assert_select('td') do
      assert_select(
        "a[href=#][onclick*=?][onclick*=?][onclick*=?]",
        "new Ajax.Request", "method:'delete'",
        "Effect.Fade('user_#{@user.id}'",
        :text => 'Delete'
      )
      assert_select(
        "a[href=?]",
        "/admin/blog_posts/new?blog_post%5Buser_id%5D=#{@user.id}",
        :text => "New blog post"
      )
    end
  end
  
  def test_index_with_a_user_with_an_avatar
    @user.update_attributes :has_avatar => true, :avatar_version => 9
    get "/admin/users"
    
    # should show the avatar image in the avatar column
    assert_select(
      'img[src=?]', "http://my-image-server.com/users/#{@user.id}.jpg?v=9"
    )
  end

  def test_index_search
    User.destroy_all
    @john_doe = User.create! :username => 'johndoe'
    @jane_doe = User.create! :username => 'janedoe', :password => "ihatejohn"
    get "/admin/users", :search => "john"
    assert_response :success
    
    # should match username
    assert_select('td', :text => 'johndoe')
    
    # should not match password
    assert_no_match(%r|<td[^>]*>janedoe</td>|, response.body)
  end
  
  def test_index_search_across_first_name_and_last_name
    User.destroy_all
    @john_doe = User.create!(
      :username => 'johndoe', :first_name => 'john', :last_name => 'doe'
    )
    get "/admin/users", :search => "john doe"
    
    # should match
    assert_select('td', :text => 'johndoe')
  end
  
  def test_new
    get "/admin/users/new"
    
    # should not show an input for password
    assert_match(/autogenerated/, response.body)
    assert_no_match(%r|<input[^>]*name="user\[password\]"|, response.body)
    
    # should not show a reset password checkbox
    assert_select("input[type=checkbox][name=reset_password]", false)
    
    # should use date dropdowns with nil defaults for birthday
    nums_and_dt_fields = {1 => :year, 2 => :month, 3 => :day}
    nums_and_dt_fields.each do |num, dt_field|
      name = "user[birthday(#{num}i)]"
      assert_select('select[name=?]', name) do
        assert_select "option[value='']"
        assert_select(
          "option:not([selected])[value=?]", Time.now.send(dt_field).to_s
        )
      end
    end
    
    # should not try to set an hour or minute for birthday
    nums_and_dt_fields = {4 => :hour, 5 => :min}
    nums_and_dt_fields.each do |num, dt_field|
      name = "blog_post[published_at(#{num}i)]"
      assert_select('select[name=?]', name, false)
    end
    
    # should respect start_year and end_year parameters
    assert_select("select[name='user[birthday(1i)]']") do
      (Time.now.year-100).upto(Time.now.year) do |year|
        assert_select "option[value='#{year}']"
      end
    end
    
    # should show a drop-down for US states
    assert_select('select[name=?]', 'user[state]') do
      assert_select "option[value='']"
      assert_select "option:not([selected])[value=AK]", :text => 'Alaska'
      assert_select "option:not([selected])[value=NY]", :text => 'New York'
      # blank option, 50 states, DC, Puerto Rico == 53 options
      assert_select "option", :count => 53
    end
    
    # should have a multipart form
    assert_select('form[enctype=multipart/form-data]')
    
    # should have a file input for tmp_avatar
    assert_match(
      %r|<input[^>]*name="user\[tmp_avatar\]"[^>]*type="file"|, response.body
    )
    
    # should show a drop-down for force_blog_posts_to_textile
    assert_select('select[name=?]', 'user[force_blog_posts_to_textile]') do
      assert_select "option[value='']"
      assert_select "option:not([selected])[value=0]", :text => 'false'
      assert_select "option:not([selected])[value=1]", :text => 'true'
    end
    
    # should show a select for admin_level
    assert_select("select[name=?]", "user[admin_level]") do
      assert_select("option[value='']", false)
      assert_select "option[value=normal][selected=selected]"
      assert_select "option[value=admin]"
      assert_select "option[value=superuser]"
    end
  end
  
  def test_update
    post(
      "/admin/users/update/#{@user.id}",
      :user => {:username => 'bettie', :force_blog_posts_to_textile => ''}
    )
    @user.reload
  
    # should not assign a new random password
    assert_equal(@user.password, 'crocker')
  
    # should know the difference between nil and false for force_blog_posts_to_textile
    assert_nil(@user.force_blog_posts_to_textile)
  end
  
  def test_update_while_resetting_password
    post(
      "/admin/users/update/#{@user.id}",
      :user => {:username => 'bettie'}, :reset_password => '1'
    )
    
    # should assign a new random password
    @user.reload
    assert_not_equal(@user.password, 'crocker')
  end
  
  def test_update_while_updating_the_current_tmp_avatar
    @user.update_attributes :has_avatar => true, :avatar_version => 9
    post(
      "/admin/users/update/#{@user.id}",
      :user => {
        :tmp_avatar => fixture_file_upload('../../spec/data/tweenbot.jpg')
      },
      :html => {:multipart => true}
    )
    
    # should increment the avatar_version through before_save
    @user.reload
    assert_equal(@user.avatar_version, 10)
  end
  
  def test_update_while_removing_the_current_tmp_avatar
    @user.update_attributes :has_avatar => true, :avatar_version => 9
    post(
      "/admin/users/update/#{@user.id}",
      :user => {:tmp_avatar => '', 'tmp_avatar(destroy)' => '1'},
      :html => {:multipart => true}
    )
      
    # should set has_avatar to false
    @user.reload
    assert(!@user.has_avatar?)
  end
  
  def test_while_trying_to_update_and_remove_tmp_avatar_at_the_same_time
    @user.update_attributes :has_avatar => true, :avatar_version => 9
    post(
      "/admin/users/update/#{@user.id}",
      :user => {
        :tmp_avatar => fixture_file_upload('../../spec/data/tweenbot.jpg'),
        'tmp_avatar(destroy)' => '1'
      },
      :html => {:multipart => true}
    )

    # should assume you meant to update
    @user.reload
    assert_equal(@user.avatar_version, 10)
    assert(@user.has_avatar?)
  end
end
