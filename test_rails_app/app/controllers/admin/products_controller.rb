class Admin::ProductsController < ApplicationController
  layout 'admin'

  admin_assistant_for Product do |a|
  end
end
