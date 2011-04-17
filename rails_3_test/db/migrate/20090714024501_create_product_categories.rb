class CreateProductCategories < ActiveRecord::Migration
  def self.up
    create_table :product_categories do |t|
      t.string :category_name

      t.timestamps
    end
    add_column :products, :product_category_id, :integer
  end

  def self.down
    remove_column :products, :product_category_id
    drop_table :product_categories
  end
end
