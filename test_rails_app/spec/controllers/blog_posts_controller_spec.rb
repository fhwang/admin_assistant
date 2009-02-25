require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe BlogPostsController do
  integrate_views

  describe '#create' do
    it 'should not be defined by admin_assistant' do
      lambda { post :create }.should raise_error(
        ActionController::UnknownAction
      )
    end
  end
end
