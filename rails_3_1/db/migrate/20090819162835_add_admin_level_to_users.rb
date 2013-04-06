class AddAdminLevelToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :admin_level, :string, :default => 'normal'
  end

  def self.down
    remove_column :users, :admin_level
  end
end
