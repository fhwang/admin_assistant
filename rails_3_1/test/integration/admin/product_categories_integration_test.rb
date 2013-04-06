require File.expand_path(File.dirname(__FILE__) + "/../../test_helper")

class Admin::ProductCategoriesIntegrationTest < 
      ActionController::IntegrationTest
  def test_index_with_no_records
    ProductCategory.destroy_all
    get "/admin/product_categories"
    
    # should say 'No product categories found'
    assert_match(/No product categories found/, response.body)
  end
end
