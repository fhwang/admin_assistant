require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::BlogPosts2Controller do
  integrate_views
  
  before :all do
    User.destroy_all
    @user = User.create! :username => 'soren'
  end
  
  describe '#index?all=1' do
    before :all do
      BlogPost.create!(
        :title => "--published--", :published_at => Time.now.utc,
        :user => @user
      )
    end
      
    before :each do
      get :index, :all => '1'
      response.should be_success
    end

    it 'should show published posts' do
      response.body.should match(/--published--/)
    end
    
    it 'should show a sort link for titles that includes all=1' do
      assert_a_tag_with_get_args(
        'Title', '/admin/blog_posts2',
        {:sort => 'title', :sort_order => 'asc', :all => '1'}, response.body
      )
    end
      
    it "should have a header of 'Blog posts (all)'" do
      response.should have_tag('h2', :text => 'Blog posts (all)')
    end
  end
  
  describe '#index?all=1 with two published posts' do
    before :all do
      BlogPost.create!(
        :title => 'published later', :published_at => Time.utc(2009, 2, 1),
        :user => @user
      )
      BlogPost.create!(
        :title => 'published earlier', :published_at => Time.utc(2009, 1, 1),
        :user => @user
      )
    end
    
    before :each do
      get :index, :all => '1'
    end
    
    it 'should order by published_at desc' do
      response.body.should match(/published later.*published earlier/m)
    end
  end
  
  describe '#index when searching for foobar' do
    before :all do
      BlogPost.destroy_all
      BlogPost.create!(
        :title => 'textile_false_foobar', :textile => false, :user => @user
      )
      BlogPost.create!(
        :title => 'textile_true_foobar', :textile => true, :user => @user
      )
      BlogPost.create!(
        :title => 'not_in_the_title', :textile => false,
        :body => 'foobar here though', :user => @user
      )
      BlogPost.create!(
        :title => 'textile is false', :textile => false,
        :body => "body doesn't say f**bar", :user => @user
      )
      BlogPost.create!(
        :title => 'already published', :textile => false,
        :body => "body doesn't say f**bar", :user => @user,
        :published_at => Time.now.utc
      )
    end
    
    describe "for title with 'foobar'" do
      before :each do
        get(
          :index,
          :search => {
            :body => "", :title => "foobar", :textile => "", :id => "",
            :user => ''
          }
        )
        response.should be_success
      end
      
      it 'should match records where textile=true' do
        response.should have_tag('td', :text => 'textile_true_foobar')
      end
      
      it 'should match records where textile=false' do
        response.should have_tag('td', :text => 'textile_false_foobar')
      end
        
      it "should show the textile and title search fields pre-set" do
        response.should have_tag('form[id=search_form][method=get]') do
          with_tag('input[name=?][value=foobar]', 'search[title]')
          with_tag('select[name=?]', 'search[textile]') do
            with_tag("option[value=''][selected=selected]", :text => '')
            with_tag("option[value='true']", :text => 'Yes')
            with_tag("option[value='false']", :text => 'No')
          end
        end
      end
    end
    
    describe "for title with 'foobar' and textile=false" do
      before :each do
        get(
          :index,
          :search => {
            :textile => 'false', :title => 'foobar', '(all_or_any)' => 'all',
            :user => ''
          }
        )
        response.should be_success
      end
      
      it "should show blog posts with textile=false and the word 'foobar' in the title" do
        response.should have_tag('td', :text => 'textile_false_foobar')
      end
      
      it "should not show a blog post with textile=true" do
        response.should_not have_tag('td', :text => 'textile_true_foobar')
      end
      
      it "should not show a blog post just 'cause it has 'foobar' in the body" do
        response.should_not have_tag('td', :text => 'not_in_the_title')
      end
        
      it "should show the textile, title, and all-or-any search fields pre-set" do
        response.should have_tag('form[id=search_form][method=get]') do
          with_tag(
            'input[type=radio][name=?][value=all][checked=checked]',
            'search[(all_or_any)]'
          )
          with_tag('input[name=?][value=foobar]', 'search[title]')
          with_tag('select[name=?]', 'search[textile]') do
            with_tag("option[value='']", :text => '')
            with_tag("option[value='true']", :text => 'Yes')
            with_tag("option[value='false'][selected=selected]", :text => 'No')
          end
        end
      end
    end
    
    describe "for title with 'foobar' or textile=false" do
      before :each do
        get(
          :index,
          :search => {
            :textile => 'false', :title => 'foobar', '(all_or_any)' => 'any',
            :user => ''
          }
        )
        response.should be_success
      end
      
      it "should show a blog post with 'foobar' in the title" do
        response.should have_tag('td', :text => 'textile_true_foobar')
      end
      
      it "should show a blog post with textile=false" do
        response.should have_tag('td', :text => 'textile is false')
      end
      
      it "should not show a blog post that's already published, because of the conditions set in controller" do
        response.should_not have_tag('td', :text => 'already published')
      end
      
      it "should show the textile, title, and all-or-any search fields pre-set" do
        response.should have_tag('form[id=search_form][method=get]') do
          with_tag(
            'input[type=radio][name=?][value=any][checked=checked]',
            'search[(all_or_any)]'
          )
          with_tag('input[name=?][value=foobar]', 'search[title]')
          with_tag('select[name=?]', 'search[textile]') do
            with_tag("option[value='']", :text => '')
            with_tag("option[value='true']", :text => 'Yes')
            with_tag("option[value='false'][selected=selected]", :text => 'No')
          end
        end
      end
    end
  end
  
  describe '#index when searching by user and there are less than 15 users' do
    before :all do
      @user2 = User.create! :username => 'Jean-Paul'
      User.count.downto(14) do
        user = User.find(
          :first,
          :conditions => [
            'username != ? and username != ?', @user.username, @user.username
          ]
        )
        user.destroy
      end
      BlogPost.destroy_all
      BlogPost.create! :title => "Soren's first post", :user => @user
      BlogPost.create! :title => "Soren's second post", :user => @user
      BlogPost.create! :title => "Jean-Paul's post", :user => @user2
    end
    
    before :each do
      get(
        :index,
        :search => {:textile => '', :title => '', :user_id => @user2.id.to_s}
      )
      response.should be_success
    end
    
    it 'should show blog posts by Jean-Paul' do
      response.should have_tag('td', :text => "Jean-Paul's post")
    end
    
    it 'should not show blog posts by Soren' do
      response.should_not have_tag('td', :text => "Soren's first post")
      response.should_not have_tag('td', :text => "Soren's second post")
    end
    
    it 'should show the user field pre-set' do
      response.should have_tag(
        'form[id=search_form][method=get]', :text => /Title/
      ) do
        with_tag('select[name=?]', 'search[user_id]') do
          with_tag("option[value='']", :text => '')
          with_tag("option[value=?][selected=selected]", @user2.id)
        end
      end
    end
  end
  
  describe '#index when searching by user and there are more than 15 users' do
    before :all do
      @blog_post = BlogPost.create! :title => random_word, :user => @user
      User.count.upto(16) do |i|
        User.create! :username => "--user #{i}--"
      end
    end
    
    before :each do
      get(
        :index,
        :search => {:textile => '', :title => '', :user_id => @user.id.to_s}
      )
      response.should be_success
    end
    
    it 'should show pre-populated user autocomplete in the search form' do
      response.should_not have_tag("select[name=?]", "search[user_id]]")
      response.should have_tag(
        "input[id=user_autocomplete_input][value=?]", @user.username
      )
      response.should have_tag(
        "input[type=hidden][name=?][id=search_user_id][value=?]",
        "search[user_id]", @user.id.to_s
      )
      response.should have_tag("div[id=user_autocomplete_palette]")
      response.should have_tag('div[id=clear_user_link]')
      response.body.should match(
        %r|
          new\s*AdminAssistant.RestrictedAutocompleter\(
          \s*"user",
          \s*"search_user_id",
          \s*"/admin/blog_posts2/autocomplete_user",
          [^)]*"includeBlank":\s*true
        |mx
      )
    end
  end
  
  describe '#index with a blank search' do
    before :each do
      get(
        :index,
        :search => {
          :body => '', :title => '', :textile => '', :id => '', :user_id => '',
          '(all_or_any)' => 'all', 'id(comparator)' => ''
        }
      )
    end
    
    it 'should be successful' do
      response.should be_success
    end
  end
  
  describe '#index with one record with a false textile field' do
    before :all do
      BlogPost.destroy_all
      @blog_post = BlogPost.create!(
        :title => random_word, :user => @user, :textile => false
      )
    end
    
    before :each do
      get :index
    end
      
    it 'should make the textile field an Ajax toggle' do
      toggle_div_id = "blog_post_#{@blog_post.id}_textile"
      post_url =
          "/admin/blog_posts2/update/#{@blog_post.id}?" +
          CGI.escape('blog_post[textile]') + "=1&amp;from=#{toggle_div_id}"
      response.should have_tag("div[id=?]", toggle_div_id) do
        ajax_substr = "new Ajax.Updater('#{toggle_div_id}', '#{post_url}'"
        with_tag("a[href=#][onclick*=?]", ajax_substr, :text => 'No')
      end
    end
  end
    
  describe '#index with 11 blog posts' do
    before :all do
      BlogPost.destroy_all
      1.upto(11) do |i|
        BlogPost.create!(
          :title => "--post #{i}--", :user => @user
        )
      end
    end
    
    before :each do
      get :index
    end
    
    it 'should show link to page 2' do
      response.should have_tag("a[href=/admin/blog_posts2?page=2]")
    end
    
    it 'should say 11 blog posts found' do
      response.body.should match(/11 blog posts found/)
    end

    it 'should mark the table rows with custom CSS class' do
      response.should have_tag('tr[class~="custom_tr_css_class"]')
    end

    it 'should mark the user cells with custom CSS class' do
      response.should have_tag('td[class~="custom_td_css_class"]', :text => @user.username)
    end
  end

  describe '#new' do
    before :all do
      Tag.find_or_create_by_tag 'tag_from_yesterday'
    end
    
    before :each do
      get :new
    end
    
    it 'should show a field for tags' do
      response.body.should match(%r|<input.*name="blog_post\[tags\]"|m)
    end
    
    it 'should show current tags' do
      response.body.should match(/tag_from_yesterday/)
    end
    
    it "should show a checkbox for the 'publish' virtual field" do
      if %w(2.3.2 2.3.3 2.3.4).include?(RAILS_GEM_VERSION)
        response.body.should match(
          %r!
            <input[^>]*
            (name="blog_post\[publish\][^>]*type="hidden"[^>]value="0"|
            type="hidden"[^>]*name="blog_post\[publish\][^>]value="0")
            .*
            <input[^>]*
            (name="blog_post\[publish\][^>]*type="checkbox"[^>]value="1"|
             type="checkbox"[^>]*name="blog_post\[publish\][^>]value="1")
          !x
        )
      elsif %w(2.1.0 2.1.2 2.2.2).include?(RAILS_GEM_VERSION)
        response.body.should match(
          %r!
            <input[^>]*
            (name="blog_post\[publish\][^>]*type="checkbox"[^>]value="1"|
             type="checkbox"[^>]*name="blog_post\[publish\][^>]value="1")
            .*
            <input[^>]*
            (name="blog_post\[publish\][^>]*type="hidden"[^>]value="0"|
            type="hidden"[^>]*name="blog_post\[publish\][^>]value="0")
          !x
        )
      else
        raise "I don't have a specified behavior for #{RAILS_GEM_VERSION}"
      end
    end
    
    it "should not duplicate the DOM ID of the 'publish' checkbox on the page" do
      response.body.scan(/id="blog_post_publish"|id="blog_post\[publish\]"/).size.should == 1
    end
    
    it "should show the description for the 'publish' virtual field" do
      response.body.should match(
        /Click this and published_at will be set automatically/
      )
    end
    
    it 'should show a preview button' do
      response.should have_tag('input[type=submit][value=Preview]')
    end
    
    it 'should use a textarea for the body field' do
      response.should have_tag(
        'textarea[name=?][cols=20][rows=40]', 'blog_post[body]'
      )
    end
    
    it "should use a checkbox for the boolean field 'textile'" do
      response.body.should match(
        %r!
          <input[^>]*
          (name="blog_post\[textile\][^>]*type="checkbox"|
           type="checkbox"[^>]*name="blog_post\[textile\])
        !x
      )
    end
    
    it "should say 'Author' instead of 'User'" do
      response.body.should match(/Author/)
    end
  end
  
  describe '#show' do
    before :all do
      @blog_post = BlogPost.create! :title => random_word, :user => @user
    end
    
    before :each do
      get :show, :id => @blog_post.id
      response.should be_success
    end
    
    it 'should show user' do
      response.body.should match(/soren/)
    end
    
    it 'should not show created at' do
      response.body.should_not match(/Created at/)
    end
  end
  
  describe '#update' do
    before :all do
      @blog_post = BlogPost.create! :title => random_word, :user => @user
    end
    
    describe 'when there are no validation errors' do
      before :each do
        post(
          :update,
          :id => @blog_post.id, :blog_post => {:tags => 'tag1 tag2 tag3'}
        )
      end
      
      it 'should set the tags_string' do
        @blog_post.reload.tags_string.should match(/tag1,tag2,tag3/)
      end
    end
    
    describe "when the user has clicked 'Preview'" do
      before :each do
        title2 = random_word
        post(
          :update,
          :id => @blog_post.id, :blog_post => {:title => title2},
          :commit => 'Preview'
        )
      end
      
      it 'should redirect to the edit page with the preview flag' do
        response.should redirect_to(
          :action => 'edit', :id => @blog_post.id, :preview => '1'
        )
      end
    end
  end

  describe '#update with a bad tag' do
    before :all do
      @blog_post = BlogPost.create! :title => random_word, :user => @user
    end
    
    before :each do
      post(
        :update,
        :id => @blog_post.id,
        :blog_post => {:tags => "foo bar! baz"}
      )
    end
    
    it 'should render a useful error' do
      response.should have_tag("div.errorExplanation") do
        with_tag 'li', :text => "Tags contain invalid string 'bar!'"
      end
    end
    
    it 'should highlight the tag string entry' do
      response.should have_tag("div.fieldWithErrors") do
        with_tag "input[name=?][value=?]", "blog_post[tags]", "foo bar! baz"
      end
    end
  end
  
  describe '#update with a bad tag and a missing title' do
    before :all do
      @blog_post = BlogPost.create! :title => random_word, :user => @user
    end
    
    before :each do
      post(
        :update,
        :id => @blog_post.id,
        :blog_post => {:tags => "foo bar! baz", :title => ''}
      )
    end
    
    it 'should render a useful tags error' do
      response.should have_tag("div.errorExplanation") do
        with_tag 'li', :text => "Tags contain invalid string 'bar!'"
      end
    end
    
    it 'should highlight the tag string entry' do
      response.should have_tag("div.fieldWithErrors") do
        with_tag "input[name=?][value=?]", "blog_post[tags]", "foo bar! baz"
      end
    end
    
    it 'should render a useful title error' do
      response.should have_tag("div.errorExplanation") do
        with_tag 'li', :text => "Title can't be blank"
      end
    end
    
    it 'should highlight the title string entry' do
      response.should have_tag("div.fieldWithErrors") do
        with_tag "input[name=?][value=?]", "blog_post[title]", ""
      end
    end
  end
end
