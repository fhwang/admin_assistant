require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::Misconfigured1Controller do
  integrate_views
  
  before :all do
    User.destroy_all
    @user = User.create! :username => 'soren', :password => 'password'
  end
  
  describe '#index' do
    it 'should raise an explanatory error' do
      lambda {
        get :index
      }.should raise_error(
        ActionView::TemplateError,
        /Virtual search column :has_something needs a conditions block/
      )
    end
  end
end
