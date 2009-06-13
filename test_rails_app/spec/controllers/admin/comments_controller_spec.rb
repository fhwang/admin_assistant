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
end
