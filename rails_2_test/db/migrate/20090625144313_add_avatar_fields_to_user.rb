class AddAvatarFieldsToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :has_avatar, :boolean, :default => false
    add_column :users, :avatar_version, :integer
  end

  def self.down
    remove_column :users, :avatar_version
    remove_column :users, :has_avatar
  end
end
