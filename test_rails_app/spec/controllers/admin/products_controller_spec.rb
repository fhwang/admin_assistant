require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::ProductsController do
  integrate_views

  describe '#new' do
    before :each do
      get :new
      response.should be_success
    end
    
    it 'should not render the default price input' do
      response.should_not have_tag("input[name=?]", 'product[price]')
    end
    
    it 'should render the custom price input from _price_input.html.erb' do
      response.should have_tag("input[name=?]", 'product[price][dollars]')
    end
  end
end
