class Admin::ProductsController < ApplicationController
  layout 'admin'

  admin_assistant_for Product do |a|
    a.actions :index, :create, :update, :destroy

    a.destroy do |product|
      product.update_attribute :deleted_at, Time.now.utc
    end

    a.form do |form|
      form.columns :name, :price, :file_column_image, :percent_off, 
                   :sale_starts_at, :sale_ends_at
      form[:file_column_image].image_size = '100x100'
      form[:sale_starts_at].nilify_link = 'Not on sale'
      form[:sale_ends_at].nilify_link = "Sale doesn't end"
    end
    
    a.index do |index|
      index.columns :id, :name, :price, :file_column_image
      index.conditions 'deleted_at is null'
      index.search :name, :price
    end
  end
  
  protected
  
  def price_from_form(price)
    (price[:dollars].to_i * 100) + price[:cents].to_i
  end
end
