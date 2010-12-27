require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class Admin::BlogPosts4IntegrationTest < ActionController::IntegrationTest
  def setup
    User.destroy_all
    @user = User.create! :username => 'soren'
  end
  
  def test_index
    BlogPost.create!(
      :published_at => Time.utc(2009, 9, 1, 12, 30, 0), :user => @user,
      :title => 'whatever'
    )
    get "/admin/blog_posts4"
    assert_response :success

    # should show datetime stuff in the search form for published_at
    assert_select(
      'form[id=search_form][method=get]', :text => /Title/
    ) do
      assert_select('select[name=?]', 'search[published_at(comparator)]') do
        assert_select("option[value=?]", ">", :text => 'greater than')
        assert_select("option[value=?]", "<", :text => 'less than')
      end
      nums_and_dt_fields = {
        1 => :year, 2 => :month, 3 => :day, 4 => :hour, 5 => :min
      }
      nums_and_dt_fields.each do |num, dt_field|
        name = "search[published_at(#{num}i)]"
        value_for_now_option = Time.now.send(dt_field).to_s
        if [:hour, :min].include?(dt_field) && value_for_now_option.size == 1
          value_for_now_option = "0#{value_for_now_option}"
        end
        assert_select('select[name=?]', name) do
          assert_select "option[value='']"
          assert_select "option[value=?]", value_for_now_option
        end
      end
      assert_select(
        "a.clear_datetime_select[rel=search_published_at]",
        :text => 'Clear'
      )
    end
    
    # should use strftime_format for displaying published_at
    assert_select('td', :text => "Sep 01, 2009 12:30:00")
  end
  
  def test_index_when_searching_by_published_at_with_a_greater_than_comparator
    @jun_blog_post = BlogPost.create!(
      :published_at => Time.utc(2009,6,1), :title => 'June', :user => @user
    )
    @aug_blog_post = BlogPost.create!(
      :published_at => Time.utc(2009,8,1), :title => 'August', :user => @user
    )
    get(
      "/admin/blog_posts4",
      :search => {
        :textile => '', :title => '', :user_id => '',
        'published_at(comparator)' => '>',
        'published_at(1i)' => '2009', 'published_at(2i)' => '7', 
        'published_at(3i)' => '1', 'published_at(4i)' => '1', 
        'published_at(5i)' => '1'
      }
    )
    assert_response :success
    
    # should include a blog post with a published_at time after the entered time
    assert_select('td', :text => 'August')

    # should not include a blog post with a published_at time before the entered time
    assert_no_match(%r|<td[^>]*>June</td>|, response.body)
    
    # should show the right fields pre-filled in the search form
    assert_select(
      'form[id=search_form][method=get]', :text => /Title/
    ) do
      assert_select('select[name=?]', 'search[published_at(comparator)]') do
        assert_select(
          "option[value=?][selected=selected]", ">", :text => 'greater than'
        )
        assert_select("option[value=?]", "<", :text => 'less than')
      end
      assert_select('select[name=?]', 'search[published_at(1i)]') do
        assert_select "option[value=?][selected=selected]", "2009"
      end
      assert_select('select[name=?]', 'search[published_at(2i)]') do
        assert_select "option[value=?][selected=selected]", "7"
      end
      assert_select('select[name=?]', 'search[published_at(3i)]') do
        assert_select "option[value=?][selected=selected]", "1"
      end
      assert_select('select[name=?]', 'search[published_at(4i)]') do
        assert_select "option[value=?][selected=selected]", "01"
      end
      assert_select('select[name=?]', 'search[published_at(5i)]') do
        assert_select "option[value=?][selected=selected]", "01"
      end
    end
  end
  
  def test_index_when_searching_by_published_at_with_a_less_than_comparator
    @jun_blog_post = BlogPost.create!(
      :published_at => Time.utc(2009,6,1), :title => 'June', :user => @user
    )
    @aug_blog_post = BlogPost.create!(
      :published_at => Time.utc(2009,8,1), :title => 'August', :user => @user
    )
    get(
      "/admin/blog_posts4",
      :search => {
        :textile => '', :title => '', :user_id => '',
        'published_at(comparator)' => '<',
        'published_at(1i)' => '2009', 'published_at(2i)' => '7', 
        'published_at(3i)' => '1', 'published_at(4i)' => '1', 
        'published_at(5i)' => '1'
      }
    )
    assert_response :success
    
    # should not include a blog post with a published_at time after the entered time
    assert_no_match(%r|<td[^>]*>August</td>|, response.body)

    # should include a blog post with a published_at time before the entered time
    assert_select('td', :text => 'June')
    
    # should show the right fields pre-filled in the search form
    assert_select(
      'form[id=search_form][method=get]', :text => /Title/
    ) do
      assert_select('select[name=?]', 'search[published_at(comparator)]') do
        assert_select "option[value=?]", ">", :text => 'greater than'
        assert_select(
          "option[value=?][selected=selected]", "<", :text => 'less than'
        )
      end
      assert_select('select[name=?]', 'search[published_at(1i)]') do
        assert_select "option[value=?][selected=selected]", "2009"
      end
      assert_select('select[name=?]', 'search[published_at(2i)]') do
        assert_select "option[value=?][selected=selected]", "7"
      end
      assert_select('select[name=?]', 'search[published_at(3i)]') do
        assert_select "option[value=?][selected=selected]", "1"
      end
      assert_select('select[name=?]', 'search[published_at(4i)]') do
        assert_select "option[value=?][selected=selected]", "01"
      end
      assert_select('select[name=?]', 'search[published_at(5i)]') do
        assert_select "option[value=?][selected=selected]", "01"
      end
    end
  end
  
  def test_index_with_26_unpublished_blog_posts
    BlogPost.destroy_all
    1.upto(26) do |i|
      BlogPost.create!(
        :title => "--post #{i}--", :user => @user, :published_at => nil
      )
    end
    get "/admin/blog_posts4"
    
    # should not show link to page 2
    assert_select("a[href=/admin/blog_posts4?page=2]", false)
    
    # should only say 25 blog posts found
    assert_match(/25 blog posts found/, response.body)
  end
  
  def test_new
    get "/admin/blog_posts4/new"
    
    # should use a textarea for virtual_text
    assert_select("textarea[name=?]", "blog_post[virtual_text]")
  end

  def test_show
    @blog_post = BlogPost.create!(
      :published_at => Time.utc(2009, 9, 1, 12, 30, 0), :user => @user,
      :title => 'whatever'
    )
    get "/admin/blog_posts4/show/#{@blog_post.id}"
    assert_response :success
    
    # should use strftime_format for displaying published_at
    assert_match(/Sep 01, 2009 12:30:00/, response.body)
  end
end
