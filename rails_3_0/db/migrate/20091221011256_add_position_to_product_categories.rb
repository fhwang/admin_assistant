class AddPositionToProductCategories < ActiveRecord::Migration
  def self.up
    add_column :product_categories, :position, :integer
  end

  def self.down
    remove_column :product_categories, :position
  end
end
