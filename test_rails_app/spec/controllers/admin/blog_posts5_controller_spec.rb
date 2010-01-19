require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::BlogPosts5Controller do
  integrate_views
  
  before :all do
    User.destroy_all
    @soren = User.create! :username => 'soren'
    @jean = User.create! :username => 'jean'
  end
  
  describe '#create with title_alt' do
    before :each do
      post(
        :create,
        :blog_post => {
          :user_id => @soren.id, :title => '', :title_alt => 'alternate field'
        }
      )
      response.should be_redirect
    end
    
    it 'should use the value of title alt for the title' do
      bp = BlogPost.last
      bp.title.should == 'alternate field'
    end
  end
  
  describe '#index' do
    before :all do
      BlogPost.create!(
        :published_at => Time.utc(2009, 9, 1, 12, 30, 0), :user => @soren,
        :title => 'whatever'
      )
      BlogPost.create!(
        :published_at => Time.utc(2009, 9, 1, 12, 30, 0), :user => @soren,
        :title => 'just do it'
      )
    end
    
    before :each do
      get :index
      response.should be_success
    end
    
    it 'should render the filter.html.erb partial' do
      response.should have_tag('ul.aa_filter')
      response.should have_tag('ul.aa_filter li a', :text => "soren")
      response.should have_tag('td', :text => "whatever")
      response.should have_tag('td', :text => "just do it")
    end
  end
  
  describe '#index?filter=@soren.id' do
    before :all do
      BlogPost.create!(
        :published_at => Time.utc(2009, 9, 1, 12, 30, 0), :user => @soren,
        :title => 'whatever'
      )
      BlogPost.create!(
        :published_at => Time.utc(2009, 9, 1, 12, 30, 0), :user => @soren,
        :title => 'whatever'
      )
    end
    
    before :each do
      get :index, :filter => @soren.id
      response.should be_success
    end
    
    it 'should filter blog posts by user id' do
      response.should have_tag('td', :text => "whatever")
      response.should_not have_tag('td', :text => "just do it")
    end
  end
  
end
