class Admin::Products2Controller < ApplicationController
  layout 'admin'

  admin_assistant_for Product do |a|
    a.index do |index|
      index.columns :id, :name, :price, :product_category
      index[:product_category].sort_by = 'category_name'
    end
  end
end

