class ProductCategory < ActiveRecord::Base
  validates_presence_of   :category_name, :position
  validates_uniqueness_of :category_name, :allow_nil => true
  validates_uniqueness_of :position, :allow_nil => true
  
  def name_for_admin_assistant
    category_name
  end
end
