class Admin::Products2Controller < ApplicationController
  layout 'admin'

  admin_assistant_for Product do |a|
    a.index do |index|
      index.columns :id, :name, :price, :product_category
      index[:product_category].sort_by = 'category_name'
      index.search do |search|
        search.columns :name, :price
        search[:price].compare_to_range = true
      end
    end
  end
end

