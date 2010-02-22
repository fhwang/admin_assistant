require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Admin::Products2Controller do
  integrate_views
  
  describe '#new' do
    before :all do
      ProductCategory.destroy_all
      @shiny = ProductCategory.create!(
        :category_name => 'shiny', :position => 1
      )
      @fuzzy = ProductCategory.create!(
        :category_name => 'fuzzy', :position => 2
      )
    end
    
    before :each do
      get :new
    end
    
    it 'should be successful' do
      response.should be_success
    end
    
    it 'should show a product category selector with category name strings' do
      response.should have_tag(
        "select[name=?]", "product[product_category_id]"
      ) do
        with_tag "option[value=#{@fuzzy.id}]", :text => "fuzzy"
        with_tag "option[value=#{@shiny.id}]", :text => "shiny"
      end
    end
  end
  
  describe '#index' do
    before :all do
      if Product.count == 0
        Product.create! :name => random_word
      end
    end
    
    before :each do
      get :index
    end
  
    it 'should show a search range widget' do
      response.should have_tag('form#search_form') do
        with_tag 'input[name=?]', 'search[price][gt]'
        with_tag 'input[name=?]', 'search[price][lt]'
        without_tag 'input[type=checkbox]'
      end
    end
  end
  
  describe '#index when searching for a product greater than a specific price' do
    before :all do
      @five_dollars = Product.find_by_price 500
      @five_dollars ||= Product.create!(:name => random_word, :price => 500)
      @fifty_dollars = Product.find_by_price 5000
      @fifty_dollars ||= Product.create!(:name => random_word, :price => 5000)
      @five_hundred_dollars = Product.find_by_price 50000
      @five_hundred_dollars ||= Product.create!(
        :name => random_word, :price => 50000
      )
    end
    
    before :each do
      get :index, :search => {:price => {:gt => "5000", :lt => ""}}
    end
  
    it 'should prefill the search form fields' do
      response.should have_tag('form#search_form') do
        with_tag 'input[name=?][value=?]', 'search[price][gt]', 5000
        with_tag 'input:not([value])[name=?]', 'search[price][lt]'
        without_tag 'input[type=checkbox]'
      end
    end
  
    it 'should not show a product lower than that price' do
      response.should_not have_tag('td', :text => @five_dollars.name)
    end
    
    it 'should not show a product at exactly that price' do
      response.should_not have_tag('td', :text => @fifty_dollars.name)
    end
    
    it 'should show a product greater than that price' do
      response.should have_tag('td', :text => @five_hundred_dollars.name)
    end
  end
  
  describe '#index when searching for a product lower than a specific price' do
    before :all do
      @five_dollars = Product.find_by_price 500
      @five_dollars ||= Product.create!(:name => random_word, :price => 500)
      @fifty_dollars = Product.find_by_price 5000
      @fifty_dollars ||= Product.create!(:name => random_word, :price => 5000)
      @five_hundred_dollars = Product.find_by_price 50000
      @five_hundred_dollars ||= Product.create!(
        :name => random_word, :price => 50000
      )
    end
    
    before :each do
      get :index, :search => {:price => {:gt => "", :lt => "5000"}}
    end
  
    it 'should prefill the search form fields' do
      response.should have_tag('form#search_form') do
        with_tag 'input:not([value])[name=?]', 'search[price][gt]'
        with_tag 'input[name=?][value=?]', 'search[price][lt]', 5000
        without_tag 'input[type=checkbox]'
      end
    end
    
    it 'should show a product lower than that price' do
      response.should have_tag('td', :text => @five_dollars.name)
    end
    
    it 'should not show a product at exactly that price' do
      response.should_not have_tag('td', :text => @fifty_dollars.name)
    end
    
    it 'should not show a product greater than that price' do
      response.should_not have_tag('td', :text => @five_hundred_dollars.name)
    end
  end
  
  describe '#index when searching for a product within a price range' do
    before :all do
      @five_dollars = Product.find_by_price 500
      @five_dollars ||= Product.create!(:name => random_word, :price => 500)
      @fifty_dollars = Product.find_by_price 5000
      @fifty_dollars ||= Product.create!(:name => random_word, :price => 5000)
      @five_hundred_dollars = Product.find_by_price 50000
      @five_hundred_dollars ||= Product.create!(
        :name => random_word, :price => 50000
      )
    end
    
    before :each do
      get :index, :search => {:price => {:gt => "1000", :lt => "10000"}}
    end

    it 'should prefill the search form fields' do
      response.should have_tag('form#search_form') do
        with_tag 'input[name=?][value=?]', 'search[price][gt]', 1000
        with_tag 'input[name=?][value=?]', 'search[price][lt]', 10000
        without_tag 'input[type=checkbox]'
      end
    end
    
    it 'should not show a product lower than that range' do
      response.should_not have_tag('td', :text => @five_dollars.name)
    end
    
    it 'should show a product in that range' do
      response.should have_tag('td', :text => @fifty_dollars.name)
    end
    
    it 'should not show a product higher than that range' do
      response.should_not have_tag('td', :text => @five_hundred_dollars.name)
    end
  end
 
  describe '#index sort by product category' do
    before :all do
      ProductCategory.destroy_all
      Product.destroy_all
      diamond_cat = ProductCategory.create!(
        :category_name => 'diamond', :position => 1
      )
      @diamond = Product.create!(
        :name => 'Diamond', :price => 200_000, :product_category => diamond_cat
      )
      choc_cat = ProductCategory.create!(
        :category_name => 'chocolate', :position => 2
      )
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
