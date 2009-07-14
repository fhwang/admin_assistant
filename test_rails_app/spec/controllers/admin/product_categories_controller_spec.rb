require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::ProductCategoriesController do
  integrate_views

  describe '#index with no records' do
    before :all do
      ProductCategory.destroy_all
    end
    
    before :each do
      get :index
    end
    
    it "should say 'No product categories found'" do
      response.body.should match(/No product categories found/)
    end
  end
end
