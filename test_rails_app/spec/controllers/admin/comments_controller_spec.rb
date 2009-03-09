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
end
