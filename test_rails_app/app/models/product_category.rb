class ProductCategory < ActiveRecord::Base
  def name_for_admin_assistant
    category_name
  end
end
