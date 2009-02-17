require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::BlogPostsController do
  integrate_views
  
  describe '#index' do
    it 'should show all fields by default' do
      BlogPost.create! :title => "hi there"
      get :index
      response.should be_success
      response.body.should match(/hi there/)
    end
    
    describe 'when there are no records' do
      it 'should say "No records"' do
        get :index
        response.should be_success
        response.body.should match(/No records/)
      end
    end
  end
end
