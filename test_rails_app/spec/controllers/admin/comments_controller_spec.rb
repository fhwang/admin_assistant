require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::CommentsController do
  integrate_views
  
  describe '#edit' do
    before :all do
      @comment = Comment.create! :comment => "you think you're so smart"
    end
    
    before :each do
      get :edit, :id => @comment.id
    end
    
    it 'should not allow the comments to be editable' do
      response.body.should match(/you think you're so smart/)
      response.should_not have_tag('textarea')
    end
  end
  
  describe "#index with a comment without the word 'smart'" do
    before :all do
      Comment.create! :comment => "something else"
    end
    
    before :each do
      get :index
    end
    
    it 'should not include the index' do
      response.body.should_not match(/something else/)
    end
  end
  
  describe '#new with at least 16 blog posts and 16 users' do
    before :all do
      user = User.find_or_create_by_username 'soren'
      BlogPost.count.upto(16) do
        BlogPost.create! :title => random_word, :user => user
      end
      User.count.upto(16) do
        User.create! :username => random_word
      end
    end
    
    before :each do
      get :new
    end
    
    it 'should be a success' do
      response.should be_success
    end
  end
end
