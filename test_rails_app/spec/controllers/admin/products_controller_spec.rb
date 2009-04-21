require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::ProductsController do
  integrate_views
  
  describe '#index' do
    before :each do
      get :index
    end
    
    it 'should have a search form that allows you to specify equals or other options' do
      response.should have_tag('form[id=search_form][method=get]') do
        with_tag("select[name=?]", "search[price(comparator)]") do
          with_tag("option[value='>']", :text => 'greater than')
          with_tag("option[value='>=']", :text => 'greater than or equal to')
          with_tag("option[value='=']", :text => 'equal to')
          with_tag("option[value='<=']", :text => 'less than or equal to')
          with_tag("option[value='<']", :text => 'less than')
        end
        with_tag('input[name=?]', 'search[price]')
      end
    end
  end
  
  describe '#index search by price' do
    before :all do
      Product.destroy_all
      Product.create!(:name => 'Chocolate bar', :price => 200)
      Product.create!(:name => 'Diamond ring', :price => 200_000)
    end
    
    before :each do
      get :index, :search => {"price(comparator)" => '>', :price => 1000}
    end
    
    it 'should only show products more expensive than $10' do
      response.should_not have_tag('td', :text => 'Chocolate bar')
      response.should have_tag('td', :text => 'Diamond ring')
    end
    
    it 'should show the price comparison in the search form' do
      response.should have_tag('form[id=search_form][method=get]') do
        with_tag("select[name=?]", "search[price(comparator)]") do
          with_tag(
            "option[value='>'][selected=selected]", :text => 'greater than'
          )
          with_tag("option[value='>=']", :text => 'greater than or equal to')
          with_tag("option[value='=']", :text => 'equal to')
          with_tag("option[value='<=']", :text => 'less than or equal to')
          with_tag("option[value='<']", :text => 'less than')
        end
        with_tag('input[name=?]', 'search[price]')
      end
    end
  end

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
