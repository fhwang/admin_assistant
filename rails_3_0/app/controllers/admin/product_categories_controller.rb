class Admin::ProductCategoriesController < ApplicationController
  layout 'admin'

  admin_assistant_for ProductCategory
end
