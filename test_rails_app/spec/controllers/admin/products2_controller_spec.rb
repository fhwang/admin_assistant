require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::Products2Controller do
  integrate_views
  
  describe '#new' do
    before :each do
      get :new
    end
    
    it 'should be successful' do
      response.should be_success
    end
  end
  
  describe '#index sort by product category' do
    before :all do
      Product.destroy_all
      diamond_cat = ProductCategory.create! :category_name => 'diamond'
      @diamond = Product.create!(
        :name => 'Diamond', :price => 200_000, :product_category => diamond_cat
      )
      choc_cat = ProductCategory.create! :category_name => 'chocolate'
      @chocolate = Product.create!(
        :name => 'Chocolate bar', :price => 200, :product_category => choc_cat
      )
      diamond_cat.id.should be < choc_cat.id
    end
    
    before :each do
      get :index, :sort_order => "asc", :sort => "product_category"
    end
    
    it 'should be a success' do
      response.should be_success
    end
    
    it 'should order chocolate before diamonds' do
      response.body.should match(
        %r|product_#{@chocolate.id}.*product_#{@diamond.id}|m
      )
    end
    
    it "should show ProductCategory#category_name because it's defined a #name_for_admin_assistant method" do
      response.should have_tag('td', :text => 'chocolate')
    end
  end
end
