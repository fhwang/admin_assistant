require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::BlogPosts3Controller do
  integrate_views
  
  before :all do
    User.destroy_all
    @user = User.create! :username => 'soren', :password => 'password'
  end
  
  describe '#edit' do
    before :all do
      @blog_post = BlogPost.create! :title => random_word, :user => @user
    end
    
    before :each do
      get :edit, :id => @blog_post.id
    end
    
    it 'should have a body field' do
      response.should have_tag('textarea[name=?]', 'blog_post[body]')
    end
    
    it 'should not include textile' do
      response.body.should_not match(/textile/)
    end
  end
  
  describe '#index' do
    describe 'with no blog posts' do
      before :all do
        BlogPost.destroy_all
      end
      
      before :each do
        get :index
        response.should be_success
      end

      it 'should use the activescaffold-themed CSS' do
        response.should have_tag(
          'link[href^=/stylesheets/admin_assistant/activescaffold.css]'
        )
      end
      
      it "should say 'Posts'" do
        response.should have_tag('h2', :text => 'Posts')
      end
    end
    
    describe 'with one unpublished blog post' do
      before :all do
        BlogPost.destroy_all
        @blog_post = BlogPost.create!(
          :title => "unpublished blog post", :user => @user,
          :published_at => nil
        )
      end
      
      before :each do
        $cache.flush
        get :index
      end
      
      it 'should show the blog post' do
        response.body.should match(/unpublished blog post/)
      end
      
      it "should show 'No' from having called BlogPost#published?" do
        response.should have_tag("tr[id=blog_post_#{@blog_post.id}]") do
          with_tag "td", :text => 'No'
        end
      end
    
      it 'should not have a comparator for the ID search field' do
        response.should have_tag('form[id=search_form][method=get]') do
          without_tag("select[name=?]", "search[id(comparator)]")
        end
      end
      
      it 'should have a blank checkbox for the body search field' do
        response.should have_tag('form[id=search_form][method=get]') do
          with_tag("input[type=checkbox][name=?]", "search[body(blank)]")
        end
      end
      
      it 'should render extra action links in order' do
        response.body.should match(/Short title.*Blank body/m)
      end
      
      it 'should have a trinary select for the has_short_title search field' do
        response.should have_tag('form[id=search_form][method=get]') do
          with_tag('select[name=?]', 'search[has_short_title]') do
            with_tag("option[value='']", :text => '')
            with_tag("option[value='true']", :text => 'Yes')
            with_tag("option[value='false']", :text => 'No')
          end
        end
      end
    
      it 'should show a search form with specific fields' do
        response.should have_tag(
          'form[id=search_form][method=get]', :text => /Title/
        ) do
          with_tag('input[name=?]', 'search[title]')
          with_tag('input[name=?]', 'search[body]')
          with_tag('select[name=?]', 'search[textile]') do
            with_tag("option[value='']", :text => '')
            with_tag("option[value='true']", :text => 'true')
            with_tag("option[value='false']", :text => 'false')
          end
          with_tag('label', :text => 'User')
          with_tag('input[name=?]', 'search[user]')
        end
      end
      
      it 'should set the count in memcache' do
        key =
            "AdminAssistant::Admin::BlogPosts3Controller_count_published_at_is_null_"
        $cache.read(key).should == 1
        $cache.expires_in(key).should be_close(12.hours, 5.seconds)
      end
      
      it 'should not make the textile field an Ajax toggle' do
        toggle_div_id = "blog_post_#{@blog_post.id}_textile"
        response.body.should_not match(
          %r|new Ajax.Updater\('#{toggle_div_id}'|
        )
        
=begin        
        post_url =
            "/admin/blog_posts2/update/#{@blog_post.id}?" +
            CGI.escape('blog_post[textile]') + "=1&amp;from=#{toggle_div_id}"
            
            
        response.should_not have_tag("div[id=?]", toggle_div_id) do
          ajax_substr = "new Ajax.Updater('#{toggle_div_id}', '#{post_url}'"
          with_tag("a[href=#][onclick*=?]", ajax_substr, :text => 'No')
        end
=end
      end
    end
    
    describe 'with a published blog post' do
      before :all do
        $cache.flush
        BlogPost.destroy_all
        BlogPost.create!(
          :title => "published blog post", :user => @user,
          :published_at => Time.now.utc
        )
      end
      
      before :each do
        get :index
      end
      
      it 'should not show the blog post' do
        response.body.should_not match(/published blog post/)
        response.body.should match(/No posts found/)
      end
    end
    
    describe 'when searching by user' do
      before :all do
        User.destroy_all
        tiffany = User.create!(:username => 'tiffany')
        BlogPost.create! :title => "By Tiffany", :user => tiffany
        BlogPost.create!(
          :title => "Already published", :user => tiffany,
          :published_at => Time.now
        )
        bill = User.create! :username => 'bill', :password => 'parsimony'
        BlogPost.create! :title => "By Bill", :user => bill
        brooklyn_steve = User.create!(
          :username => 'brooklyn_steve', :state => 'NY'
        )
        BlogPost.create! :title => "By Brooklyn Steve", :user => brooklyn_steve
        sadie = User.create!(
          :username => 'Sadie', :password => 'sadie', :state => 'KY'
        )
        BlogPost.create! :title => "By Sadie", :user => sadie
      end
      
      before :each do
        get(
          :index,
          :search => {
            :body => "", :textile => "", :id => "", :user => 'ny',
            :has_short_title => ''
          }
        )
        response.should be_success
      end
      
      it 'should match the string to the username' do
        response.body.should match(/By Tiffany/)
      end
      
      it 'should match the string to the password' do
        response.body.should match(/By Bill/)
      end
      
      it 'should match the string to the state' do
        response.body.should match(/By Brooklyn Steve/)
      end
      
      it "should skip blog posts that don't match anything on the user" do
        response.body.should_not match(/By Sadie/)
      end
      
      it 'should skip blog posts that have already been published' do
        response.body.should_not match(/Already published/)
      end
    end
    
    describe 'with blog posts from two different users' do
      before :all do
        aardvark_man = User.create!(:username => 'aardvark_man')
        BlogPost.create! :title => 'AARDVARKS!!!!!1', :user => aardvark_man
        ziggurat = User.create!(:username => 'zigguratz')
        BlogPost.create! :title => "Wanna go climbing?", :user => ziggurat
      end
      
      before :each do
        get :index
        response.should be_success
      end
      
      it 'should sort by username' do
        response.body.should match(%r|AARDVARKS!!!!!1.*Wanna go climbing|m)
      end
    end
  end
  
  describe '#index when search for a blank body' do
    before :all do
      BlogPost.destroy_all
      @nil_body_post = BlogPost.create!(
        :title => "nil", :user => @user, :body => nil
      )
      @empty_string_body_post = BlogPost.create!(
        :title => "empty string", :user => @user, :body => ''
      )
      @non_blank_body_post = BlogPost.create!(
        :title => "non-blank", :user => @user, :body => 'foo'
      )
    end
    
    before :each do
      get(
        :index,
        :search => {
          "body(blank)" => '1', :user => '', :body => '', :title => '', 
          :textile => '', :id => '', '(all_or_any)' => 'all',
          :has_short_title => ''
        }
      )
    end
    
    it 'should retrieve a blog post with a nil body' do
      response.should have_tag("tr[id=?]", "blog_post_#{@nil_body_post.id}")
    end
    
    it 'should retrieve a blog post with a space-only string body' do
      response.should have_tag(
        "tr[id=?]", "blog_post_#{@empty_string_body_post.id}"
      )
    end
    
    it 'should not retrieve a blog post with a non-blank body' do
      response.should_not have_tag(
        "tr[id=?]", "blog_post_#{@non_blank_body_post.id}"
      )
    end
      
    it 'should have a checked blank checkbox for the body search field' do
      response.should have_tag('form[id=search_form][method=get]') do
        with_tag(
          "input[type=checkbox][checked=checked][name=?]", 
          "search[body(blank)]"
        )
      end
    end
  end
  
  describe '#index when searching and there are blog posts with varying title lengths' do
    before :all do
      BlogPost.destroy_all
      @bp1 = BlogPost.create!(
        :title => 'short', :body => 'foobar', :user => @user
      )
      @bp2 = BlogPost.create!(
        :title => "longer title", :body => 'foobar', :user => @user
      )
    end
    
    describe 'when searching for short-titled blog posts' do
      before :each do
        get(
          :index,
          :search => {
            :body => "", "body(blank)" => '0', :textile => "", :id => "",
            :user => '', :has_short_title => 'true'
          }
        )
      end
      
      it 'should return a short-titled blog post' do
        response.should have_tag('td', :text => 'short')
      end
      
      it 'should not return a longer-title blog post' do
        response.should_not have_tag('td', :text => 'longer title')
      end
      
      it "should pre-select 'true' in the has_short_title search field" do
        response.should have_tag('form[id=search_form][method=get]') do
          with_tag('select[name=?]', 'search[has_short_title]') do
            with_tag("option[value='']", :text => '')
            with_tag("option[value='true'][selected=selected]", :text => 'Yes')
            with_tag("option[value='false']", :text => 'No')
          end
        end
      end
    end
    
    describe 'when searching for long-titled blog posts' do
      before :each do
        get(
          :index,
          :search => {
            :body => "", "body(blank)" => '0', :textile => "", :id => "",
            :user => '', :has_short_title => 'false'
          }
        )
      end

      it 'should not return a short-titled blog post' do
        response.should_not have_tag('td', :text => 'short')
      end
      
      it 'should return a longer-title blog post' do
        response.should have_tag('td', :text => 'longer title')
      end
      
      it "should pre-select 'false' in the has_short_title search field" do
        response.should have_tag('form[id=search_form][method=get]') do
          with_tag('select[name=?]', 'search[has_short_title]') do
            with_tag("option[value='']", :text => '')
            with_tag("option[value='true']", :text => 'Yes')
            with_tag("option[value='false'][selected=selected]", :text => 'No')
          end
        end
      end
    end
    
    describe 'when searching for blog posts of any title-length' do
      before :each do
        get(
          :index,
          :search => {
            :body => 'foobar', "body(blank)" => '0', :textile => "", :id => "",
            :user => '', :has_short_title => ''
          }
        )
      end
      
      it 'should return a short-titled blog post' do
        response.should have_tag('td', :text => 'short')
      end
      
      it 'should return a longer-title blog post' do
        response.should have_tag('td', :text => 'longer title')
      end
    end
  end
  
  describe '#index when searching by ID' do
    before :all do
      BlogPost.destroy_all
      @blog_post1 = BlogPost.create! :title => random_word, :user => @user
      blog_post2 = BlogPost.create! :title => random_word, :user => @user
      BlogPost.update_all(
        "id = #{@blog_post1.id * 10}", "id = #{blog_post2.id}"
      )
      @blog_post2 = BlogPost.find(@blog_post1.id * 10)
    end
    
    before :each do
      get(
        :index,
        :search => {
          :body => '', "body(blank)" => '0', :textile => "",
          :id => @blog_post1.id.to_s, :user => '', :has_short_title => ''
        }
      )
    end
    
    it 'should match the record with that ID' do
      response.should have_tag("tr[id=?]", "blog_post_#{@blog_post1.id}")
    end
    
    it 'should not match a record with an ID that has the ID as a substring' do
      response.should_not have_tag("tr[id=?]", "blog_post_#{@blog_post2.id}")
    end
  end
  
  describe '#index when the blank-body count has been cached in memcache but the request is looking for the default index' do
    before :all do
      $cache.flush
      another_key = 
          "AdminAssistant::Admin::BlogPosts3Controller_count__body_is_null_or_body______"
      $cache.write another_key, 1_000_000, :expires_in => 12.hours
    end
    
    before :each do
      get :index
    end
    
    it 'should not read a value from memcache' do
      response.body.should_not match(/1000000 posts found/)
    end

    it 'should set the count in memcache' do
      key =
          "AdminAssistant::Admin::BlogPosts3Controller_count_published_at_is_null_"
      $cache.read(key).should_not be_nil
      $cache.expires_in(key).should be_close(12.hours, 5.seconds)
    end
  end
  
  describe '#index when the count has been cached in memcache' do
    before :all do
      key =
          "AdminAssistant::Admin::BlogPosts3Controller_count_published_at_is_null_"
      $cache.write key, 1_000_000, :expires_in => 12.hours
    end
    
    before :each do
      $cache.raise_on_write
      get :index
    end
    
    it 'should read memcache and not hit the database' do
      response.body.should match(/1000000 posts found/)
    end
  end
  
  describe '#new' do
    before :each do
      @request_time = Time.now.utc
      get :new
    end
    
    it 'should not have a body field' do
      response.should_not have_tag('textarea[name=?]', 'blog_post[body]')
    end
    
    it 'should have a published_at select that starts in the year 2009' do
      name = 'blog_post[published_at(1i)]'
      response.should have_tag('select[name=?]', name) do
        with_tag "option[value='2009']"
        with_tag "option[value='2010']"
        without_tag "option[value='2008']"
      end
    end
    
    it 'should have a published_at select that is set to now' do
      name = 'blog_post[published_at(3i)]'
      response.should have_tag('select[name=?]', name) do
        with_tag "option[value=?][selected=selected]", @request_time.day
      end
    end
    
    it 'should not show a nullify link for published_at' do
      response.body.should_not have_tag(
        'a', :text => "Set \"published at\" to nil"
      )
    end
    
    it "should say 'New post'" do
      response.should have_tag('h2', :text => 'New post')
    end
  end
  
  describe '#show' do
    before :all do
      @blog_post = BlogPost.create! :title => "title", :user => @user
    end
    
    before :each do
      get :show, :id => @blog_post.id
      response.should be_success
    end
    
    it "should say 'Post [ID]'" do
      response.should have_tag('h2', :text => "Post #{@blog_post.id}")
    end
  end
end
