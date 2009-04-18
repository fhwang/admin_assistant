require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::BlogPosts3Controller do
  integrate_views
  
  before :all do
    User.destroy_all
    @user = User.create! :username => 'soren'
  end
  
  describe '#index' do
    describe 'with 26 unpublished blog posts' do
      before :all do
        BlogPost.destroy_all
        1.upto(26) do |i|
          BlogPost.create!(
            :title => "--post #{i}--", :user => @user, :published_at => nil
          )
        end
      end
      
      before :each do
        get :index
      end
      
      it 'should not show link to page 2' do
        response.should_not have_tag("a[href=/admin/blog_posts3?page=2]")
      end
      
      it 'should only say 25 blog posts found' do
        response.body.should match(/25 blog posts found/)
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
    end
    
    describe 'with a published blog post' do
      before :all do
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
        response.body.should match(/No blog posts found/)
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
        get :index, :search => {
          :body => "", :textile => "", :id => "", :user => 'ny'
        }
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
  end
end
