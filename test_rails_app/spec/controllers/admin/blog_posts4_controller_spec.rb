require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::BlogPosts4Controller do
  integrate_views
  
  before :all do
    User.destroy_all
    @user = User.create! :username => 'soren'
  end
  
  describe '#index' do
    before :all do
      BlogPost.create!(
        :published_at => Time.utc(2009, 9, 1, 12, 30, 0), :user => @user,
        :title => 'whatever'
      )
    end
    
    before :each do
      get :index
      response.should be_success
    end
    
    it 'should show datetime stuff in the search form for published_at' do
      response.should have_tag(
        'form[id=search_form][method=get]', :text => /Title/
      ) do
        with_tag('select[name=?]', 'search[published_at(comparator)]') do
          with_tag("option[value=?]", ">", :text => 'greater than')
          with_tag("option[value=?]", "<", :text => 'less than')
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
          response.should have_tag('select[name=?]', name) do
            with_tag "option[value='']"
            with_tag "option[value=?]", value_for_now_option
          end
        end
        with_tag(
          "a[onclick=?]", 
          "AdminAssistant.clear_datetime_select('search_published_at'); return false;",
          :text => 'Clear'
        )
      end
    end
    
    it 'should use strftime_format for displaying published_at' do
      response.should have_tag('td', :text => "Sep 01, 2009 12:30:00")
    end
  end
  
  describe '#index when searching by published_at with a greater-than comparator' do
    before :all do
      @jun_blog_post = BlogPost.create!(
        :published_at => Time.utc(2009,6,1), :title => 'June', :user => @user
      )
      @aug_blog_post = BlogPost.create!(
        :published_at => Time.utc(2009,8,1), :title => 'August', :user => @user
      )
    end
    
    before :each do
      get(
        :index,
        :search => {
          :textile => '', :title => '', :user_id => '',
          'published_at(comparator)' => '>',
          'published_at(1i)' => '2009', 'published_at(2i)' => '7', 
          'published_at(3i)' => '1', 'published_at(4i)' => '1', 
          'published_at(5i)' => '1'
        }
      )
      response.should be_success
    end
    
    it 'should include a blog post with a published_at time after the entered time' do
      response.should have_tag('td', :text => 'August')
    end

    it 'should not include a blog post with a published_at time before the entered time' do
      response.should_not have_tag('td', :text => 'June')
    end
    
    it 'should show the right fields pre-filled in the search form' do
      response.should have_tag(
        'form[id=search_form][method=get]', :text => /Title/
      ) do
        with_tag('select[name=?]', 'search[published_at(comparator)]') do
          with_tag(
            "option[value=?][selected=selected]", ">", :text => 'greater than'
          )
          with_tag("option[value=?]", "<", :text => 'less than')
        end
        with_tag('select[name=?]', 'search[published_at(1i)]') do
          with_tag "option[value=?][selected=selected]", "2009"
        end
        with_tag('select[name=?]', 'search[published_at(2i)]') do
          with_tag "option[value=?][selected=selected]", "7"
        end
        with_tag('select[name=?]', 'search[published_at(3i)]') do
          with_tag "option[value=?][selected=selected]", "1"
        end
        with_tag('select[name=?]', 'search[published_at(4i)]') do
          with_tag "option[value=?][selected=selected]", "01"
        end
        with_tag('select[name=?]', 'search[published_at(5i)]') do
          with_tag "option[value=?][selected=selected]", "01"
        end
      end
    end
  end
  
  describe '#index when searching by published_at with a less-than comparator' do
    before :all do
      @jun_blog_post = BlogPost.create!(
        :published_at => Time.utc(2009,6,1), :title => 'June', :user => @user
      )
      @aug_blog_post = BlogPost.create!(
        :published_at => Time.utc(2009,8,1), :title => 'August', :user => @user
      )
    end
    
    before :each do
      get(
        :index,
        :search => {
          :textile => '', :title => '', :user_id => '',
          'published_at(comparator)' => '<',
          'published_at(1i)' => '2009', 'published_at(2i)' => '7', 
          'published_at(3i)' => '1', 'published_at(4i)' => '1', 
          'published_at(5i)' => '1'
        }
      )
      response.should be_success
    end
    
    it 'should not include a blog post with a published_at time after the entered time' do
      response.should_not have_tag('td', :text => 'August')
    end

    it 'should include a blog post with a published_at time before the entered time' do
      response.should have_tag('td', :text => 'June')
    end
    
    it 'should show the right fields pre-filled in the search form' do
      response.should have_tag(
        'form[id=search_form][method=get]', :text => /Title/
      ) do
        with_tag('select[name=?]', 'search[published_at(comparator)]') do
          with_tag "option[value=?]", ">", :text => 'greater than'
          with_tag(
            "option[value=?][selected=selected]", "<", :text => 'less than'
          )
        end
        with_tag('select[name=?]', 'search[published_at(1i)]') do
          with_tag "option[value=?][selected=selected]", "2009"
        end
        with_tag('select[name=?]', 'search[published_at(2i)]') do
          with_tag "option[value=?][selected=selected]", "7"
        end
        with_tag('select[name=?]', 'search[published_at(3i)]') do
          with_tag "option[value=?][selected=selected]", "1"
        end
        with_tag('select[name=?]', 'search[published_at(4i)]') do
          with_tag "option[value=?][selected=selected]", "01"
        end
        with_tag('select[name=?]', 'search[published_at(5i)]') do
          with_tag "option[value=?][selected=selected]", "01"
        end
      end
    end
  end

  describe '#show' do
    before :all do
      @blog_post = BlogPost.create!(
        :published_at => Time.utc(2009, 9, 1, 12, 30, 0), :user => @user,
        :title => 'whatever'
      )
    end
    
    before :each do
      get :show, :id => @blog_post.id
      response.should be_success
    end
    
    it 'should use strftime_format for displaying published_at' do
      response.body.should match(/Sep 01, 2009 12:30:00/)
    end
  end
end
