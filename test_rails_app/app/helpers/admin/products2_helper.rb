module Admin::Products2Helper
  def product_category_html_for_index(product)
    product.product_category.category_name if product.product_category
  end
end

