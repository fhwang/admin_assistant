class AddDeletedAtToProducts < ActiveRecord::Migration
  def self.up
    add_column :products, :deleted_at, :datetime
  end

  def self.down
    remove_column :products, :deleted_at
  end
end
