class Admin::ProductsController < ApplicationController
  layout 'admin'

  admin_assistant_for Product do |a|
    a.actions :index, :create, :update, :destroy
    a.index.search do |search|
      search.columns :name, :price
      search[:price].comparators = :all
    end
  end
  
  protected
  
  def price_from_form(price)
    (price[:dollars].to_i * 100) + price[:cents].to_i
  end
end
