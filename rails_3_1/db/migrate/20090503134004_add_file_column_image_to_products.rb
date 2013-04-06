class AddFileColumnImageToProducts < ActiveRecord::Migration
  def self.up
    add_column :products, :file_column_image, :string
  end

  def self.down
    remove_column :products, :file_column_image
  end
end
