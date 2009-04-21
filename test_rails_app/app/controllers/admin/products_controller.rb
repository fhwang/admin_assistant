class Admin::ProductsController < ApplicationController
  layout 'admin'

  admin_assistant_for Product do |a|
    a.index.search do |search|
      search.columns :name, :price
      search.comparators[:price] = :all
    end
  end
end
