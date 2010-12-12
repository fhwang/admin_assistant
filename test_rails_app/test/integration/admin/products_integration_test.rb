require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class Admin::ProductsIntegrationTest < ActionController::IntegrationTest
  def test_destroy
    @product = Product.find_or_create_by_name 'Chocolate bar'
    post "/admin/products/destroy/#{@product.id}"
    
    # should call the custom destroy block
    @product.reload
    assert_not_nil(@product.deleted_at)
  end
  
  def test_index_with_at_least_one_Product
    @product = (
      Product.find(:first) || Product.create!(:name => 'product name')
    )
    get "/admin/products"
    
    # should have a search form that allows you to specify equals or other options
    assert_select('form[id=search_form][method=get]') do
      assert_select("select[name=?]", "search[price(comparator)]") do
        assert_select("option[value='>']", :text => 'greater than')
        assert_select("option[value='>=']", :text => 'greater than or equal to')
        assert_select("option[value='='][selected=selected]", :text => 'equal to')
        assert_select("option[value='<=']", :text => 'less than or equal to')
        assert_select("option[value='<']", :text => 'less than')
      end
      assert_select('input[name=?]', 'search[price]')
    end
    
    # should not have a comparator for the name search field
    assert_select('form[id=search_form][method=get]') do
      assert_select("select[name=?]", "search[name(comparator)]", false)
    end
    
    # should not have a Show link
    assert_no_match(%r|<a[^>]*>Show</a>|, response.body)
  end
  
  def test_index_search_by_price
    Product.destroy_all
    Product.create!(:name => 'Chocolate bar', :price => 200)
    Product.create!(:name => 'Diamond ring', :price => 200_000)
    get "/admin/products", :search => {"price(comparator)" => '>', :price => 1000}
    
    # should only show products more expensive than $10
    assert_no_match(%r|<td[^>]*>Chocolate bar</td>|, response.body)
    assert_select('td', :text => 'Diamond ring')
    
    # should show the price comparison in the search form
    assert_select('form[id=search_form][method=get]') do
      assert_select("select[name=?]", "search[price(comparator)]") do
        assert_select(
          "option[value='>'][selected=selected]", :text => 'greater than'
        )
        assert_select("option[value='>=']", :text => 'greater than or equal to')
        assert_select("option[value='=']", :text => 'equal to')
        assert_select("option[value='<=']", :text => 'less than or equal to')
        assert_select("option[value='<']", :text => 'less than')
      end
      assert_select('input[name=?]', 'search[price]')
    end
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
    get "/admin/products", :sort_order => "asc", :sort => "product_category"
    
    # should be a success
    assert_response :success
    
    # should order by product_category_id
    assert_match(
      %r|product_#{@diamond.id}.*product_#{@chocolate.id}|m, response.body
    )
  end
  
  def test_new
    get "/admin/products/new"
    assert_response :success
    
    # should not render the default price input
    assert_select("input[name=?]", 'product[price]', false)
    
    # should render the custom price input from _price_input.html.erb
    assert_select("input[name=?]", 'product[price][dollars]')
    
    # should show clear links for sale_starts_at and sale_ends_at
    assert_select('a', :text => "Not on sale")
    assert_select('a', :text => "Sale doesn't end")
  end
  
  def test_edit
    @product = Product.find_or_create_by_name 'a bird'
    @product.update_attributes(
      :name => 'a bird', :price => 100_00,
      :file_column_image => File.open("./spec/data/ruby_throated.jpg"),
      :percent_off => 25
    )
    get "/admin/products/edit/#{@product.id}"
    assert_response :success
    
    # should have a multipart form
    assert_select('form[enctype=multipart/form-data]')
    
    # should have a file input for image
    assert_select(
      'input[name=?][type=file]', 'product[file_column_image]'
    )
    
    # should show the current image
    assert_select(
      "img[src^=?][height=100][width=100]",
      "/product/file_column_image/#{@product.id}/ruby_throated.jpg"
    )
    
    # should have a remove-image option
    assert_select(
      "input[type=checkbox][name=?]", 'product[file_column_image(destroy)]'
    )
    
    # should the percent_off value pre-filled
    assert_select(
      'input[name=?][value=25]', 'product[percent_off]'
    )
  end
  
  def test_update_while_updating_a_current_image
    @product = Product.find_or_create_by_name 'a bird'
    @product.update_attributes(
      :name => 'a bird', :price => 100_00,
      :file_column_image => File.open("./spec/data/ruby_throated.jpg")
    )
    file = File.new './spec/data/tweenbot.jpg'
    post(
      "/admin/products/update/#{@product.id}", 
      :product => {
        :file_column_image => fixture_file_upload(
          "../../spec/data/tweenbot.jpg"
        )
      },
      :html => {:multipart => true}
    )
      
    # should update the image
    product_prime = Product.find_by_id @product.id
    assert_match(/tweenbot/, product_prime.file_column_image)
    
    # should save the image locally
    assert(
      File.exist?(
        "./public/product/file_column_image/#{@product.id}/tweenbot.jpg"
      )
    )
  end    
    
  def test_update_while_removing_the_current_image
    @product = Product.find_or_create_by_name 'a bird'
    @product.update_attributes(
      :name => 'a bird', :price => 100_00,
      :file_column_image => File.open("./spec/data/ruby_throated.jpg")
    )
    post(
      "/admin/products/update/#{@product.id}",
      :product => {
        'file_column_image(destroy)' => '1', :file_column_image => ''
      }
    )
  
    # should remove the existing image
    product_prime = Product.find_by_id @product.id
    assert_nil product_prime.file_column_image
  end
  
  def test_update_while_trying_to_update_and_remove_at_the_same_time
    @product = Product.find_or_create_by_name 'a bird'
    @product.update_attributes(
      :name => 'a bird', :price => 100_00,
      :file_column_image => File.open("./spec/data/ruby_throated.jpg")
    )
    post(
      "/admin/products/update/#{@product.id}", 
      :product => {
        :file_column_image => fixture_file_upload(
          "../../spec/data/tweenbot.jpg"
        ),
        'file_column_image(destroy)' => '1'
      },
      :html => {:multipart => true}
    )

    # should assume you meant to update
    product_prime = Product.find_by_id @product.id
    assert_match(/tweenbot/, product_prime.file_column_image)
  end
end
