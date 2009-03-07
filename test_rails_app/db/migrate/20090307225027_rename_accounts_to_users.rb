class RenameAccountsToUsers < ActiveRecord::Migration
  def self.up
    rename_table :accounts, :users
  end

  def self.down
    rename_table :users, :accounts
  end
end
