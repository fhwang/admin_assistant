class RemoveAvatarFieldsFromUsers < ActiveRecord::Migration
  def self.up
    remove_column :users, :has_avatar
    remove_column :users, :avatar_version
  end

  def self.down
    add_column :users, :avatar_version, :integer
    add_column :users, :has_avatar, :boolean, :default => false
  end
end
