class CreateTelevisionTimeSlots < ActiveRecord::Migration
  def self.up
    create_table :television_time_slots do |t|
      t.datetime :time

      t.timestamps
    end
  end

  def self.down
    drop_table :television_time_slots
  end
end
