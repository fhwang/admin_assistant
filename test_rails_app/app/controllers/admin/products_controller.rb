class Admin::ProductsController < ApplicationController
  layout 'admin'

  admin_assistant_for Product do |a|
    a.actions :index, :create, :update, :destroy

    a.index do |index|
      index.columns :id, :name, :price, :file_column_image
      index.conditions 'deleted_at is null'
      index.search :name, :price
    end
                    
    a.destroy do |product|
      product.update_attribute :deleted_at, Time.now.utc
    end
  end
  
  protected
  
  def price_from_form(price)
    (price[:dollars].to_i * 100) + price[:cents].to_i
  end
end
