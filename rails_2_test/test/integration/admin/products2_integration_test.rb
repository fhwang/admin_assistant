require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class Admin::Products2IntegrationTest < ActionController::IntegrationTest
  def test_new
    ProductCategory.destroy_all
    @shiny = ProductCategory.create!(
      :category_name => 'shiny', :position => 1
    )
    @fuzzy = ProductCategory.create!(
      :category_name => 'fuzzy', :position => 2
    )
    get "/admin/products2/new"
    
    # should be successful
    assert_response :success
    
    # should show a product category selector with category name strings
    assert_select("select[name=?]", "product[product_category_id]") do
      assert_select "option[value=#{@fuzzy.id}]", :text => "fuzzy"
      assert_select "option[value=#{@shiny.id}]", :text => "shiny"
    end
  end
  
  def test_index
    if Product.count == 0
      Product.create! :name => random_word
    end
    get "/admin/products2"
  
    # should show a search range widget
    assert_select('form#search_form') do
      assert_select 'input[name=?]', 'search[price][gt]'
      assert_select 'input[name=?]', 'search[price][lt]'
      assert_select('input[type=checkbox]', false)
    end
  end

  def test_index_when_searching_for_a_product_greater_than_a_specific_price
    @five_dollars = Product.find_by_price 500
    @five_dollars ||= Product.create!(:name => random_word, :price => 500)
    @fifty_dollars = Product.find_by_price 5000
    @fifty_dollars ||= Product.create!(:name => random_word, :price => 5000)
    @five_hundred_dollars = Product.find_by_price 50000
    @five_hundred_dollars ||= Product.create!(
      :name => random_word, :price => 50000
    )
    get "/admin/products2", :search => {:price => {:gt => "5000", :lt => ""}}
  
    # should prefill the search form fields
    assert_select('form#search_form') do
      assert_select 'input[name=?][value=?]', 'search[price][gt]', 5000
      assert_select 'input:not([value])[name=?]', 'search[price][lt]'
      assert_select('input[type=checkbox]', false)
    end
  
    # should not show a product lower than that price
    assert_no_match(%r|<td[^>]*>#{@five_dollars.name}</td>|, response.body)
    
    # should not show a product at exactly that price
    assert_no_match(%r|<td[^>]*>#{@fifty_dollars.name}</td>|, response.body)
    
    # should show a product greater than that price
    assert_select('td', :text => @five_hundred_dollars.name)
  end
  
  def test_index_when_searching_for_a_product_lower_than_a_specific_price
    @five_dollars = Product.find_by_price 500
    @five_dollars ||= Product.create!(:name => random_word, :price => 500)
    @fifty_dollars = Product.find_by_price 5000
    @fifty_dollars ||= Product.create!(:name => random_word, :price => 5000)
    @five_hundred_dollars = Product.find_by_price 50000
    @five_hundred_dollars ||= Product.create!(
      :name => random_word, :price => 50000
    )
    get "/admin/products2", :search => {:price => {:gt => "", :lt => "5000"}}
  
    # should prefill the search form fields
    assert_select('form#search_form') do
      assert_select 'input:not([value])[name=?]', 'search[price][gt]'
      assert_select 'input[name=?][value=?]', 'search[price][lt]', 5000
      assert_select('input[type=checkbox]', false)
    end
    
    # should show a product lower than that price
    assert_select('td', :text => @five_dollars.name)
    
    # should not show a product at exactly that price
    assert_no_match(%r|<td[^>]*>#{@fifty_dollars.name}</td>|, response.body)
    
    # should not show a product greater than that price
    assert_no_match(
      %r|<td[^>]*>#{@five_hundred_dollars.name}</td>|, response.body
    )
  end
  
  def test_index_when_searching_for_a_product_within_a_price_range
    @five_dollars = Product.find_by_price 500
    @five_dollars ||= Product.create!(:name => random_word, :price => 500)
    @fifty_dollars = Product.find_by_price 5000
    @fifty_dollars ||= Product.create!(:name => random_word, :price => 5000)
    @five_hundred_dollars = Product.find_by_price 50000
    @five_hundred_dollars ||= Product.create!(
      :name => random_word, :price => 50000
    )
    get "/admin/products2", :search => {:price => {:gt => "1000", :lt => "10000"}}

    # should prefill the search form fields
    assert_select('form#search_form') do
      assert_select 'input[name=?][value=?]', 'search[price][gt]', 1000
      assert_select 'input[name=?][value=?]', 'search[price][lt]', 10000
      assert_select('input[type=checkbox]', false)
    end
    
    # should not show a product lower than that range
    assert_no_match(%r|<td[^>]*>#{@five_dollars.name}</td>|, response.body)
    
    # should show a product in that range
    assert_select('td', :text => @fifty_dollars.name)
    
    # should not show a product higher than that range
    assert_no_match(
      %r|<td[^>]*>#{@five_hundred_dollars.name}</td>|, response.body
    )
  end
 
  def test_index_sort_by_product_category
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
    assert(diamond_cat.id < choc_cat.id)
    get "/admin/products2", :sort_order => "asc", :sort => "product_category"
    
    # should be a success
    assert_response :success
    
    # should order chocolate before diamonds
    assert_match(
      %r|product_#{@chocolate.id}.*product_#{@diamond.id}|m, response.body
    )
    
    # should show ProductCategory#category_name because it's defined a #name_for_admin_assistant method
    assert_select('td', :text => 'chocolate')
  end
end
