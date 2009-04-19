require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::Comments2Controller do
  integrate_views

  describe '#new' do
    before :each do
      get :new
    end
    
    it 'should have a textarea for Comment#comment' do
      response.should have_tag("textarea[name=?]", "comment[comment]")
    end
  end
  
  describe '#edit' do
    before :all do
      @comment = Comment.create! :comment => "you're funny but I'm funnier"
    end
    
    before :each do
      get :edit, :id => @comment.id
    end
    
    it 'should not have a textarea for Comment#comment' do
      response.should_not have_tag("textarea[name=?]", "comment[comment]")
    end
  end
end
