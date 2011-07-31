class AddUserIdToAppointments < ActiveRecord::Migration
  def self.up
    add_column :appointments, :user_id, :integer
  end

  def self.down
    remove_column :appointments, :user_id
  end
end
