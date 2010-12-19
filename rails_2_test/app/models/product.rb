class Product < ActiveRecord::Base
  validates_uniqueness_of :name
  
  belongs_to :product_category
  
  file_column :file_column_image
end
