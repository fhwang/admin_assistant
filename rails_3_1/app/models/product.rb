class Product < ActiveRecord::Base
  validates_uniqueness_of :name
  
  belongs_to :product_category
end
