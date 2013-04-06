class AddSaleFieldsToProducts < ActiveRecord::Migration
  def self.up
    add_column :products, :percent_off, :integer
    add_column :products, :sale_starts_at, :datetime
    add_column :products, :sale_ends_at, :datetime
  end

  def self.down
    remove_column :products, :sale_ends_at
    remove_column :products, :sale_starts_at
    remove_column :products, :percent_off
  end
end
