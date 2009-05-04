class Product < ActiveRecord::Base
  validates_uniqueness_of :name
  
  file_column :file_column_image
end
